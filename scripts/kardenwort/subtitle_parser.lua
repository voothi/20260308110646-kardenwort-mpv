-- ===============================================================================
-- subtitle_parser.lua — Subtitle file parsing & position matching for kardenwort
-- Reads FSM/Options/Tracks/Diagnostic at call time via injected references.
-- ===============================================================================

local mp = require 'mp'
local text_utils = require 'text_utils'

local M = {}

local FSM, Options, Tracks, Diagnostic
local safe_read_file

function M.init(fsm, opts, tracks, diagnostic, safe_read_file_fn)
    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diagnostic
    safe_read_file = safe_read_file_fn
end

local function parse_time(time_str)
    local h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+),(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+)%.(%d+)")
    if h and m and s and ms then
        local ms_val = tonumber(ms)
        if #ms == 2 then ms_val = ms_val * 10 end -- Centiseconds to milliseconds
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + ms_val / 1000
    end
    return 0
end

local function load_sub(path, is_ass)
    if not path or path == "" then return {} end
    Diagnostic.info("Loading subtitle file: " .. tostring(path))
    local content = safe_read_file(path)
    if not content then
        Diagnostic.error("Failed to read subtitle file: " .. tostring(path))
        return {}
    end

    local subs = {}
    local current_sub = nil

    if is_ass then
        for line in (content .. "\n"):gmatch("(.-)\r?\n") do
            if line:match("^Dialogue:") then
                local first_colon = line:find(":")
                if first_colon then
                    local line_content = line:sub(first_colon + 1)
                    line_content = line_content:gsub("^%s+", "")
                    local parts = {}
                    local last_pos = 1
                    for i = 1, 9 do
                        local comma_pos = line_content:find(",", last_pos)
                        if not comma_pos then break end
                        table.insert(parts, line_content:sub(last_pos, comma_pos - 1))
                        last_pos = comma_pos + 1
                    end
                    if #parts == 9 then
                        local text = line_content:sub(last_pos)
                        local start_str = parts[2]:match("^%s*(.-)%s*$")
                        local end_str = parts[3]:match("^%s*(.-)%s*$")
                        if start_str and end_str and text then
                            local raw_text = text_utils.normalize_inline_break_markers(text):gsub("{[^}]+}", "")
                            raw_text = raw_text:gsub("%z", ""):match("^%s*(.-)%s*$")
                            if raw_text ~= "" then
                                local parsed_start = parse_time(start_str)
                                local parsed_end = parse_time(end_str)
                                local merged = false
                                local prev = subs[#subs]
                                if prev and prev.raw_text == raw_text then
                                    if parsed_start <= prev.end_time + 0.2 then
                                        prev.end_time = math.max(prev.end_time, parsed_end)
                                        merged = true
                                    end
                                end
                                if not merged then
                                    table.insert(subs, {
                                        start_time = parsed_start,
                                        end_time = parsed_end,
                                        text = raw_text,
                                        raw_text = raw_text
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(subs, function(a, b) return a.start_time < b.start_time end)
    else
        local state = "ID"
        for raw_line in (content .. "\n"):gmatch("(.-)\r?\n") do
            local line = text_utils.clean_text_srt(raw_line)
            if line == "" then
                if current_sub and current_sub.text ~= "" then
                    current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
                    local merged = false
                    local prev = subs[#subs]
                    if prev and prev.raw_text == current_sub.raw_text then
                        if current_sub.start_time <= prev.end_time + 0.2 then
                            prev.end_time = math.max(prev.end_time, current_sub.end_time)
                            merged = true
                        end
                    end
                    if not merged then
                        table.insert(subs, current_sub)
                    end
                end
                current_sub = nil
                state = "ID"
            elseif state == "ID" then
                if line:match("^%d+$") then
                    current_sub = {text = ""}
                    state = "TIME"
                end
            elseif state == "TIME" then
                local s, e = line:match("^(%d%d:%d%d:%d%d[,.]%d%d%d)%s*[-][-]%s*>%s*(%d%d:%d%d:%d%d[,.]%d%d%d)")
                if s and e then
                    if current_sub then
                        current_sub.start_time = parse_time(s)
                        current_sub.end_time = parse_time(e)
                    end
                    state = "TEXT"
                end
            elseif state == "TEXT" then
                if current_sub then
                    if current_sub.text == "" then
                        current_sub.text = line
                    else
                        current_sub.text = current_sub.text .. "\n" .. line
                    end
                end
            end
        end
        if current_sub and current_sub.text ~= "" then
            current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
            table.insert(subs, current_sub)
        end
    end

    if subs and #subs > 0 then
        Diagnostic.info(string.format("Parsed %d subtitles from %s", #subs, path))
    end
    return subs
end

-- Find the last sub whose start_time is <= time_pos (raw SRT window lookup).
-- Returns -1 if time_pos is before the first sub's start_time.
local function find_sub_containing_start(subs, time_pos)
    if not subs or #subs == 0 then return -1 end
    local low, high = 1, #subs
    local best = -1
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if subs[mid].start_time <= time_pos then
            best = mid
            low = mid + 1
        else
            high = mid - 1
        end
    end
    return best
end

local function get_effective_boundaries(subs, sub, idx)
    if not sub then return nil, nil end
    local pad_start = (Options.audio_padding_start or 0) / 1000
    local pad_end = (Options.audio_padding_end or 0) / 1000

    local start = sub.start_time - pad_start
    local stop = sub.end_time + pad_end

    -- Movie Mode: Seamless handover at the next subtitle's padded start.
    -- This prevents overlapping audio loops while still ensuring the pre-roll is heard.
    -- [20260510193230] PHRASE Mode: Seamless handover during rewind transit to prevent overlay/jerking.
    local hold_elapsed = mp.get_time() - (FSM.space_down_time or 0)
    local phrase_space_movie_override = FSM.AUTOPAUSE == "ON"
        and FSM.IMMERSION_MODE == "PHRASE"
        and FSM.PHYSICAL_SPACE_HOLD
        and hold_elapsed > Options.space_tap_delay

    if FSM.IMMERSION_MODE == "MOVIE"
       or phrase_space_movie_override
       or (FSM.IMMERSION_MODE == "PHRASE" and FSM.TIMESEEK_INHIBIT_UNTIL and FSM.REWIND_TRANSIT_CROSS_CARD) then
        if idx and subs and idx < #subs then
            stop = subs[idx + 1].start_time - pad_start
            -- Guard: never pause before SRT end_time (short gaps shrink the handover boundary)
            if stop < sub.end_time then stop = sub.end_time end
        end
    end

    return start, stop
end

local function get_center_index(subs, time_pos)
    if not subs or #subs == 0 then return -1 end

    -- Sticky Focus Sentinel: Prioritize the active index if we are within its padded window.
    -- This prevents "Magnetic Snapping" to adjacent subtitles when the playhead is in the padding gap.
    -- [20260507154518] Extended to secondary track via FSM.SEC_ACTIVE_IDX to prevent desync when
    -- padded windows overlap (audio_padding_end + audio_padding_start > inter-subtitle gap).
    local active_idx = (subs == Tracks.pri.subs) and FSM.ACTIVE_IDX or
                       (subs == Tracks.sec.subs and FSM.SEC_ACTIVE_IDX or -1)

    -- Jerk-Back Loop Prevention: If we just jumped to a new index in Phrases mode,
    -- don't let the sticky logic pull us back to the previous one during the overlap.
    if FSM.IMMERSION_MODE == "PHRASE" and FSM.JUST_JERKED_TO ~= -1 then
        active_idx = FSM.JUST_JERKED_TO
    end

    -- Post-manual-seek bypass: if the active index disagrees with the explicit
    -- seek target (or with the raw sub that contains time_pos), drop the sticky
    -- sentinel so progression can advance. When active_idx already matches the
    -- seek target, sticky focus is preserved (e.g. d-seek from sub 2 to sub 3
    -- should not be pulled back to sub 2 by pad-window overlap).
    if mp.get_time() < FSM.MANUAL_NAV_COOLDOWN and active_idx ~= -1 then
        local is_pri = (subs == Tracks.pri.subs)
        local target_idx = is_pri and FSM.MANUAL_NAV_TARGET_IDX or FSM.SEC_MANUAL_NAV_TARGET_IDX
        -- target_idx is nil for raw (non-script) seeks; in that case the
        -- mismatch test below still gates on the raw-window check, so the
        -- bypass only fires when time_pos is provably inside a different sub.
        if active_idx ~= target_idx then
            local best = find_sub_containing_start(subs, time_pos)
            if best ~= -1 and time_pos <= subs[best].end_time and best ~= active_idx then
                active_idx = -1
            end
        end
    end

    -- One-step Natural Progression (per immersion-engine spec).
    -- When focus on sub `i` expires and sub `i+1`'s padded zone is active,
    -- transition to `i+1` - never skip intermediate subs even when large
    -- audio_padding values cause multiple subs' padded zones to overlap time_pos.
    -- [202605091854] Priority Fix: Check for forward progression BEFORE sticky focus
    -- to ensure we don't get stuck in the overlap zone (e.g. 2.05s when sub1 ends
    -- at 2.0 and sub2 starts at 2.2 with 200ms padding).
    -- [20260509192327] Expiry Fix: Use padded end (e_current) in both PHRASE and MOVIE
    -- modes. PHRASE mode previously used raw SRT end_time, which caused premature
    -- transitions when padded windows overlapped (large padding). The sentinel should
    -- hold until the full audio window of sub i expires, regardless of immersion mode.
    if active_idx and active_idx ~= -1 and active_idx + 1 <= #subs and subs[active_idx + 1] then
        local next_idx = active_idx + 1
        local s_next, e_next = get_effective_boundaries(subs, subs[next_idx], next_idx)
        if s_next and e_next and time_pos >= s_next - Options.nav_tolerance and time_pos <= e_next then
            local _, e_current = get_effective_boundaries(subs, subs[active_idx], active_idx)

            -- Natural Progression: transition only after the current sub's padded window expires.
            if time_pos >= e_current - Options.nav_tolerance then
                return next_idx
            end
        end
    end

    if active_idx and active_idx ~= -1 and subs[active_idx] then
        local s, e = get_effective_boundaries(subs, subs[active_idx], active_idx)
        -- Tolerate sub-frame seek rounding around exact padded boundaries.
        -- Without this, manual `d` can land a few milliseconds before `s`,
        -- causing fallback to previous raw SRT index and apparent "stuck next".
        if time_pos >= (s - Options.nav_tolerance) and time_pos <= (e + Options.nav_tolerance) then
            return active_idx
        end
    end

    local best = find_sub_containing_start(subs, time_pos)
    if best == -1 then return 1 end

    -- Absolute Start Guard: If we are at the very beginning, always return first sub
    if time_pos <= 0 then return 1 end

    -- Overlap Priority: If we are in a gap where the next sub's
    -- padded start has begun, the next sub wins immediately.
    -- The Sticky Sentinel check above ensures we don't switch until the
    -- previous sub's padded end is finished.
    -- [20260509192327] Guard: Only apply Overlap Priority when we are past the
    -- current best sub's actual SRT end_time (i.e., in a true gap). When the
    -- playhead is inside subs[best]'s raw SRT window, that sub has hard priority
    -- and no padding-induced overlap from the next sub should override it.
    if best < #subs and time_pos > subs[best].end_time then
        local next_sub = subs[best + 1]
        local s_next, _ = get_effective_boundaries(subs, next_sub, best + 1)
        if time_pos >= s_next - Options.nav_tolerance then
            return best + 1
        end
    end

    if time_pos <= subs[best].end_time then
        return best
    end

    -- If we are in a gap, check the next subtitle's padded start
    if best < #subs then
        local next_sub = subs[best + 1]
        local s_next, _ = get_effective_boundaries(subs, next_sub)
        if time_pos >= s_next then
            return best + 1
        end

        -- Proximity fallback
        if (time_pos - subs[best].end_time) < (next_sub.start_time - time_pos) then
            return best
        else
            return best + 1
        end
    end

    return best
end

-- Playback-independent resolver for static grounding (TSV anchors, probes).
-- Unlike get_center_index(), this must not depend on ACTIVE_IDX sticky state.
local function get_center_index_static(subs, time_pos)
    if not subs or #subs == 0 then return -1 end

    local best = find_sub_containing_start(subs, time_pos)

    if best == -1 then return 1 end

    if time_pos <= subs[best].end_time then
        return best
    end

    if best < #subs then
        local next_sub = subs[best + 1]
        if time_pos >= next_sub.start_time then
            return best + 1
        end
        if (time_pos - subs[best].end_time) < (next_sub.start_time - time_pos) then
            return best
        else
            return best + 1
        end
    end

    return best
end

-- --- module exports --------------------------------------------------------
M.parse_time = parse_time
M.load_sub = load_sub
M.find_sub_containing_start = find_sub_containing_start
M.get_center_index = get_center_index
M.get_center_index_static = get_center_index_static
M.get_effective_boundaries = get_effective_boundaries

return M
