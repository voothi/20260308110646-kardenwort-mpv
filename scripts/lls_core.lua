local mp = require 'mp'
local utils = require 'mp.utils'

-- =========================================================================
-- LLS CORE CONFIGURATION
-- =========================================================================

local Options = {
    -- AutoPause
    autopause_default = true,
    karaoke_every_word = false,
    pause_padding = 0.15,
    karaoke_token = "{\\c}",
    space_tap_delay = 0.2,

    -- Drum Mode
    drum_font_size = 34,
    drum_context_lines = 2,
    drum_context_opacity = "50",
    drum_context_color = "FFFFFF",
    drum_context_bold = "0",
    drum_context_size_mul = 1.0,
    drum_active_opacity = "00",
    drum_active_color = "FFFFFF",
    drum_active_bold = "0",
    drum_active_size_mul = 1.0,
    drum_spacing_gap = -0.1,
    drum_stack_multiplier = 1.15,

    -- Copy Mode
    copy_default_mode = "A",
    copy_filter_russian = true,
    copy_context_lines = 2,
    copy_word_limit = 3,

    -- System
    tick_rate = 0.05,
    osd_duration = 1.0
}

-- =========================================================================
-- STATE MACHINE
-- =========================================================================

local FSM = {
    -- Media Context
    MEDIA_STATE = "NO_SUBS", -- NO_SUBS, SINGLE_SRT, SINGLE_ASS, DUAL_SRT, DUAL_ASS, DUAL_MIXED
    
    -- Feature States
    AUTOPAUSE = Options.autopause_default and "ON" or "OFF",
    KARAOKE = Options.karaoke_every_word and "WORD" or "PHRASE",
    SPACEBAR = "IDLE",
    DRUM = "OFF",
    COPY_MODE = "A",
    COPY_CONTEXT = "OFF",
    OSC_VIS = 0, -- 0=auto, 1=always, 2=never

    -- Transients
    last_paused_sub_end = nil,
    space_down_time = 0,
    initial_pause_state = true,
    native_sub_vis = true,
    native_sec_sub_vis = true
}

local Tracks = {
    pri = { id = 0, is_ass = false, path = nil, subs = {} },
    sec = { id = 0, is_ass = false, path = nil, subs = {} }
}

-- UI State pointers for Drum Mode OSD
local drum_osd = mp.create_osd_overlay("ass-events")
drum_osd.res_x = 1920
drum_osd.res_y = 1080

-- =========================================================================
-- PARSERS & UTILS
-- =========================================================================

local function parse_time(time_str)
    local h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+),(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+)%.(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    return 0
end

local function clean_text_srt(line)
    return line:gsub("\r", ""):gsub("<[^>]+>", "")
end

local function load_sub(path, is_ass)
    if not path or path == "" then return {} end
    local f = io.open(path, "r")
    if not f then return {} end
    
    local subs = {}
    local current_sub = nil

    if is_ass then
        for line in f:lines() do
            if line:match("^Dialogue:") then
                local first_colon = line:find(":")
                if first_colon then
                    local content = line:sub(first_colon + 1)
                    content = content:gsub("^%s+", "")
                    local parts = {}
                    local last_pos = 1
                    for i = 1, 9 do
                        local comma_pos = content:find(",", last_pos)
                        if not comma_pos then break end
                        table.insert(parts, content:sub(last_pos, comma_pos - 1))
                        last_pos = comma_pos + 1
                    end
                    if #parts == 9 then
                        local text = content:sub(last_pos)
                        local start_str = parts[2]:match("^%s*(.-)%s*$")
                        local end_str = parts[3]:match("^%s*(.-)%s*$")
                        if start_str and end_str and text then
                            local raw_text = text:gsub("\\N", " \n "):gsub("{[^}]+}", "")
                            raw_text = raw_text:gsub("%s+", " "):match("^%s*(.-)%s*$")
                            if raw_text ~= "" then
                                local parsed_start = parse_time(start_str)
                                local parsed_end = parse_time(end_str)
                                local merged = false
                                local search_limit = math.max(1, #subs - 10)
                                for i = #subs, search_limit, -1 do
                                    if subs[i].raw_text == raw_text then
                                        subs[i].end_time = math.max(subs[i].end_time, parsed_end)
                                        merged = true
                                        break
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
        for line in f:lines() do
            line = clean_text_srt(line)
            if line == "" then
                if current_sub and current_sub.text ~= "" then
                    current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
                    if #subs > 0 and subs[#subs].raw_text == current_sub.raw_text then
                        subs[#subs].end_time = math.max(subs[#subs].end_time, current_sub.end_time)
                    else
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
                local start_str, end_str = string.match(line, "(%S+)%s+%-%->%s+(%S+)")
                if start_str and end_str then
                    current_sub.start_time = parse_time(start_str)
                    current_sub.end_time = parse_time(end_str)
                    state = "TEXT"
                end
            elseif state == "TEXT" then
                if current_sub.text == "" then
                    current_sub.text = line
                else
                    current_sub.text = current_sub.text .. "\n" .. line
                end
            end
        end
        if current_sub and current_sub.text ~= "" then
            current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
            if #subs > 0 and subs[#subs].raw_text == current_sub.raw_text then
                subs[#subs].end_time = math.max(subs[#subs].end_time, current_sub.end_time)
            else
                table.insert(subs, current_sub)
            end
        end
    end
    f:close()
    return subs
end

local function has_cyrillic(str)
    return str:find("[\208\209]") ~= nil
end

local function show_osd(msg, dur)
    local style = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(style .. "{\\an4}{\\fs20}" .. msg, dur or Options.osd_duration)
end

local function get_center_index(subs, time_pos)
    if not subs or #subs == 0 then return -1 end
    for i = 1, #subs do
        local sub = subs[i]
        if time_pos >= sub.start_time and time_pos <= sub.end_time then return i end
        if time_pos < sub.start_time then
            if i > 1 then
                local prev = subs[i-1]
                if (time_pos - prev.end_time) < (sub.start_time - time_pos) then return i - 1 else return i end
            else return 1 end
        end
    end
    return #subs
end

-- =========================================================================
-- FSM INTERNAL LOGIC
-- =========================================================================

local function update_media_state()
    Tracks.pri.id = mp.get_property_number("sid", 0)
    Tracks.sec.id = mp.get_property_number("secondary-sid", 0)
    
    Tracks.pri.is_ass = false
    Tracks.sec.is_ass = false
    Tracks.pri.path = nil
    Tracks.sec.path = nil

    local track_list = mp.get_property_native("track-list") or {}
    
    for _, t in ipairs(track_list) do
        if t.type == "sub" then
            local is_ass = false
            local path = nil
            
            if t.external and t["external-filename"] then
                path = t["external-filename"]
                if path:lower():match("%.ass$") or path:lower():match("%.ssa$") then
                    is_ass = true
                else
                    is_ass = (t.codec == "ass" or t.codec == "ssa")
                end
            else
                is_ass = (t.codec == "ass" or t.codec == "ssa")
            end
            
            if t.id == Tracks.pri.id then
                Tracks.pri.is_ass = is_ass
                Tracks.pri.path = path
            end
            if t.id == Tracks.sec.id then
                Tracks.sec.is_ass = is_ass
                Tracks.sec.path = path
            end
        end
    end

    -- Determine State
    if Tracks.pri.id == 0 and Tracks.sec.id == 0 then
        FSM.MEDIA_STATE = "NO_SUBS"
    elseif Tracks.sec.id == 0 then
        FSM.MEDIA_STATE = Tracks.pri.is_ass and "SINGLE_ASS" or "SINGLE_SRT"
    elseif Tracks.pri.id == 0 then
        FSM.MEDIA_STATE = Tracks.sec.is_ass and "SINGLE_ASS" or "SINGLE_SRT"
    else
        if Tracks.pri.is_ass and Tracks.sec.is_ass then
            FSM.MEDIA_STATE = "DUAL_ASS"
        elseif not Tracks.pri.is_ass and not Tracks.sec.is_ass then
            FSM.MEDIA_STATE = "DUAL_SRT"
        else
            FSM.MEDIA_STATE = "DUAL_MIXED"
        end
    end

    -- If Drum Mode is ON, but MEDIA_STATE includes an ASS track, we MUST disable Drum Mode to prevent bugs
    if FSM.DRUM == "ON" then
        if FSM.MEDIA_STATE:match("ASS") then
            FSM.DRUM = "OFF"
            mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
            mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
            drum_osd.data = ""
            drum_osd:update()
            show_osd("Drum Mode: AUTO-DISABLED (ASS Track Loaded)", Options.osd_duration + 1.0)
        else
            -- Reload subtitles for Drum memory only if necessary
            if Tracks.pri.path and #Tracks.pri.subs == 0 then Tracks.pri.subs = load_sub(Tracks.pri.path, false) end
            if Tracks.sec.path and #Tracks.sec.subs == 0 then Tracks.sec.subs = load_sub(Tracks.sec.path, false) end
        end
    end
end

-- =========================================================================
-- DRUM RENDERER
-- =========================================================================

local function draw_drum(subs, center_idx, y_pos_percent, time_pos, font_size)
    if center_idx == -1 then return "" end
    
    local ass = ""
    local start_idx = math.max(1, center_idx - Options.drum_context_lines)
    local end_idx = math.min(#subs, center_idx + Options.drum_context_lines)
    
    local is_top = (y_pos_percent < 50)
    local y_pixel = y_pos_percent * 1080 / 100
    local gap = font_size * Options.drum_spacing_gap
    
    local function format_sub(sub, is_center)
        local is_active = (is_center and time_pos >= sub.start_time and time_pos <= sub.end_time)
        if is_active then
            return string.format("{\\alpha&H%s&}{\\b%s}{\\c&H%s&}{\\fs%d}%s{\\fs%d}", 
                Options.drum_active_opacity, Options.drum_active_bold, Options.drum_active_color, 
                font_size * Options.drum_active_size_mul, sub.text, font_size)
        else
            return string.format("{\\alpha&H%s&}{\\b%s}{\\c&H%s&}{\\fs%d}%s{\\fs%d}", 
                Options.drum_context_opacity, Options.drum_context_bold, Options.drum_context_color, 
                font_size * Options.drum_context_size_mul, sub.text, font_size)
        end
    end

    local prev_text = ""
    for i = start_idx, center_idx - 1 do
        if prev_text ~= "" then prev_text = prev_text .. "\\N" end
        prev_text = prev_text .. format_sub(subs[i], false)
    end
    
    local active_text = format_sub(subs[center_idx], true)
    
    local next_text = ""
    for i = center_idx + 1, end_idx do
        if next_text ~= "" then next_text = next_text .. "\\N" end
        next_text = next_text .. format_sub(subs[i], false)
    end
    
    if is_top then
        if prev_text ~= "" then ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s\n", y_pixel - gap, font_size, prev_text) end
        local main_text = active_text
        if next_text ~= "" then main_text = main_text .. "\\N" .. next_text end
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s\n", y_pixel, font_size, main_text)
    else
        local all_text = ""
        if prev_text ~= "" then all_text = prev_text .. "\\N" end
        all_text = all_text .. active_text
        if next_text ~= "" then all_text = all_text .. "\\N" .. next_text end
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s\n", y_pixel, font_size, all_text)
    end
    return ass
end

local function tick_drum(time_pos)
    if not FSM.native_sub_vis then
        drum_osd.data = ""
        drum_osd:update()
        return
    end

    local ass_text = ""
    local font_size = Options.drum_font_size > 0 and Options.drum_font_size or mp.get_property_number("sub-font-size", 44)
    local pri_pos = mp.get_property_number("sub-pos", 95)
    local sec_pos = mp.get_property_number("secondary-sub-pos", 10)
    
    if sec_pos > 50 then
        local max_lines = Options.drum_active_size_mul + (2 * Options.drum_context_lines * Options.drum_context_size_mul)
        local max_pixels = max_lines * font_size * Options.drum_stack_multiplier
        sec_pos = pri_pos - ((max_pixels / 1080) * 100)
    end
    
    if #Tracks.sec.subs > 0 then
        local idx = get_center_index(Tracks.sec.subs, time_pos)
        ass_text = ass_text .. draw_drum(Tracks.sec.subs, idx, sec_pos, time_pos, font_size)
    end
    
    if #Tracks.pri.subs > 0 then
        local idx = get_center_index(Tracks.pri.subs, time_pos)
        ass_text = ass_text .. draw_drum(Tracks.pri.subs, idx, pri_pos, time_pos, font_size)
    end
    
    drum_osd.data = ass_text
    drum_osd:update()
end

-- =========================================================================
-- AUTOPAUSE CONTROLLER
-- =========================================================================

local function tick_autopause(time_pos)
    if FSM.MEDIA_STATE == "NO_SUBS" then return end
    
    local raw_text_primary = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass") or ""
    local raw_text_secondary = mp.get_property("secondary-sub-text") or ""
    
    if raw_text_primary == "" and raw_text_secondary == "" then return end

    if FSM.KARAOKE == "PHRASE" then
        local has_karaoke = string.find(raw_text_primary, Options.karaoke_token, 1, true)
        if not has_karaoke then has_karaoke = string.find(raw_text_secondary, Options.karaoke_token, 1, true) end
        if has_karaoke then return end
    end

    local sub_end = mp.get_property_number("sub-end")
    if sub_end ~= nil then
        if (sub_end - time_pos) < Options.pause_padding and (sub_end - time_pos) > 0 then
            if FSM.last_paused_sub_end ~= sub_end then
                mp.set_property_bool("pause", true)
                FSM.last_paused_sub_end = sub_end
            end
        end
    end
end

-- =========================================================================
-- MASTER TICK LOOP
-- =========================================================================

local function master_tick()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    -- Execute Autopause
    if FSM.AUTOPAUSE == "ON" and FSM.SPACEBAR == "IDLE" then
        tick_autopause(time_pos)
    end

    -- Execute Drum rendering
    if FSM.DRUM == "ON" then
        tick_drum(time_pos)
    end
end
mp.add_periodic_timer(Options.tick_rate, master_tick)

-- =========================================================================
-- ACTION BINDINGS
-- =========================================================================

local function cmd_toggle_autopause()
    FSM.AUTOPAUSE = (FSM.AUTOPAUSE == "ON") and "OFF" or "ON"
    show_osd("Autopause: " .. FSM.AUTOPAUSE)
end

local function cmd_toggle_karaoke()
    FSM.KARAOKE = (FSM.KARAOKE == "WORD") and "PHRASE" or "WORD"
    if FSM.KARAOKE == "WORD" then
        show_osd("Pause Mode: EVERY WORD", Options.osd_duration + 0.5)
    else
        show_osd("Pause Mode: END OF PHRASE")
    end
end

local function cmd_smart_space(table)
    if table.event == "down" then
        if FSM.SPACEBAR == "IDLE" then
            FSM.SPACEBAR = "HOLDING"
            FSM.space_down_time = mp.get_time()
            FSM.initial_pause_state = mp.get_property_bool("pause", true)
            if FSM.initial_pause_state then mp.set_property_bool("pause", false) end
        end
    elseif table.event == "up" then
        FSM.SPACEBAR = "IDLE"
        if (mp.get_time() - FSM.space_down_time) <= Options.space_tap_delay then
            mp.set_property_bool("pause", not FSM.initial_pause_state)
        end
    end
end

local function cmd_toggle_drum()
    if FSM.MEDIA_STATE:match("ASS") then
        show_osd("Drum Mode: NOT SUPPORTED (ASS Track)", Options.osd_duration + 1.0)
        return
    end

    if FSM.DRUM == "OFF" then
        FSM.DRUM = "ON"
        FSM.native_sub_vis = mp.get_property_bool("sub-visibility", true)
        FSM.native_sec_sub_vis = mp.get_property_bool("secondary-sub-visibility", true)
        mp.set_property_bool("sub-visibility", false)
        mp.set_property_bool("secondary-sub-visibility", false)
        
        -- Boot subs for drum memory
        if Tracks.pri.path then Tracks.pri.subs = load_sub(Tracks.pri.path, false) end
        if Tracks.sec.path then Tracks.sec.subs = load_sub(Tracks.sec.path, false) end

        show_osd("Drum Mode: ON")
    else
        FSM.DRUM = "OFF"
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
        drum_osd.data = ""
        drum_osd:update()
        show_osd("Drum Mode: OFF")
    end
end

local function cmd_toggle_sub_vis()
    local current = (FSM.DRUM == "ON") and FSM.native_sub_vis or mp.get_property_bool("sub-visibility", true)
    local nxt = not current
    if FSM.DRUM == "ON" then
        FSM.native_sub_vis = nxt
        FSM.native_sec_sub_vis = nxt
    else
        mp.set_property_bool("sub-visibility", nxt)
        mp.set_property_bool("secondary-sub-visibility", nxt)
    end
    show_osd("Subtitles: " .. (nxt and "ON" or "OFF"))
end

local function cmd_cycle_sec_pos()
    local p = mp.get_property_number("secondary-sub-pos", 10)
    local n = (p == 10) and 90 or 10
    mp.set_property_number("secondary-sub-pos", n)
    show_osd("Secondary Sub Pos: " .. ((n == 10) and "TOP" or "BOTTOM"))
end

local function cmd_cycle_sec_sid()
    if FSM.DRUM == "ON" then FSM.native_sec_sub_vis = true
    else mp.set_property_bool("secondary-sub-visibility", true) end

    mp.command("no-osd cycle secondary-sid")
    local ssid = mp.get_property_number("secondary-sid", 0)
    if ssid == 0 then
        show_osd("Secondary Subtitles: OFF")
        return
    end

    mp.add_timeout(0.05, function()
        local tracks = mp.get_property_native("track-list") or {}
        for _, t in ipairs(tracks) do
            if t.type == "sub" and t.id == ssid then
                local label = "ON"
                if t.lang then label = t.lang:upper()
                elseif t.title then label = t.title
                elseif t["external-filename"] then
                    local fn = t["external-filename"]:match("([^/\\]+)$") or t["external-filename"]
                    local ext = fn:match("%.([A-Za-z0-9_]+)%.srt$") or fn:match("%.([A-Za-z0-9_]+)%.ass$")
                    label = ext and ext:upper() or string.sub(fn, 1, 30)
                end
                show_osd("Secondary Subtitles: " .. label)
                break
            end
        end
    end)
end

local function cmd_toggle_osc()
    FSM.OSC_VIS = (FSM.OSC_VIS + 1) % 3
    local lbl, cmd = "AUTO", "auto"
    if FSM.OSC_VIS == 1 then lbl, cmd = "ALWAYS", "always"
    elseif FSM.OSC_VIS == 2 then lbl, cmd = "NEVER", "never" end
    mp.commandv("script-message", "osc-visibility", cmd, "no-osd")
    show_osd("OSC Visibility: " .. lbl)
end

-- =========================================================================
-- COPY CONTEXT LOGIC
-- =========================================================================

local function cmd_cycle_copy_mode()
    FSM.COPY_MODE = (FSM.COPY_MODE == "A") and "B" or "A"
    show_osd("Copy Subtitle Mode: " .. FSM.COPY_MODE)
end

local function cmd_toggle_copy_ctx()
    FSM.COPY_CONTEXT = (FSM.COPY_CONTEXT == "OFF") and "ON" or "OFF"
    show_osd("Context Copy: " .. FSM.COPY_CONTEXT)
end

local function get_copy_context_text(time_pos)
    local combined = {}
    
    local function trim(s) return s:match("^%s*(.-)%s*$") or "" end
    
    local function is_target(s)
        if not s then return false end
        local cyr = has_cyrillic(s)
        if FSM.COPY_MODE == "A" then
            return not cyr
        else
            return cyr
        end
    end
    
    local function append(path, is_ass)
        if not path then return end
        local subs = nil
        if Tracks.pri.path == path and FSM.DRUM == "ON" and not is_ass then subs = Tracks.pri.subs
        elseif Tracks.sec.path == path and FSM.DRUM == "ON" and not is_ass then subs = Tracks.sec.subs
        else subs = load_sub(path, is_ass) end

        if subs and #subs > 0 then
            local idx = get_center_index(subs, time_pos)
            if idx ~= -1 then
                local pre, i = {}, idx - 1
                while i >= 1 and #pre < Options.copy_context_lines do
                    local t = trim(subs[i].text)
                    if t ~= "" and (not Options.copy_filter_russian or is_target(t)) then table.insert(pre, 1, t) end
                    i = i - 1
                end
                for _, ln in ipairs(pre) do table.insert(combined, ln) end
                
                local ctext = trim(subs[idx].text)
                if ctext ~= "" and (not Options.copy_filter_russian or is_target(ctext)) then table.insert(combined, ctext) end
                
                local post, i2 = {}, idx + 1
                while i2 <= #subs and #post < Options.copy_context_lines do
                    local t = trim(subs[i2].text)
                    if t ~= "" and (not Options.copy_filter_russian or is_target(t)) then table.insert(post, t) end
                    i2 = i2 + 1
                end
                for _, ln in ipairs(post) do table.insert(combined, ln) end
            end
        end
    end
    
    append(Tracks.pri.path, Tracks.pri.is_ass)
    if Tracks.sec.path and Tracks.sec.path ~= Tracks.pri.path then
        append(Tracks.sec.path, Tracks.sec.is_ass)
    end
    
    return #combined > 0 and table.concat(combined, "\n") or nil
end

local function cmd_copy_sub()
    local ctext = ""
    local time_pos = mp.get_property_number("time-pos")
    local is_context = false

    if FSM.COPY_CONTEXT == "ON" and time_pos then
        local ctx = get_copy_context_text(time_pos)
        if ctx and ctx ~= "" then 
            ctext = ctx 
            is_context = true
        end
    end
    
    if ctext == "" then
        local p_text = mp.get_property("sub-text") or ""
        local s_text = mp.get_property("secondary-sub-text") or ""
        ctext = p_text .. "\n" .. s_text
    end
    
    -- Clean text (remove ASS tags)
    ctext = ctext:gsub("{[^}]+}", ""):gsub("\\N", "\n")
    
    local final_text = ""
    
    if is_context then
        -- Context Copy already filtered lines internally, just join whatever it gave us
        final_text = ctext:gsub("\n", " ")
    else
        local lines = {}
        for line in ctext:gmatch("[^\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line and line ~= "" then table.insert(lines, line) end
        end
        
        if #lines > 0 then
            local valid = {}
            if Options.copy_filter_russian then
                for _, ln in ipairs(lines) do
                    local cyr = has_cyrillic(ln)
                    if (FSM.COPY_MODE == "A" and not cyr) or (FSM.COPY_MODE == "B" and cyr) then table.insert(valid, ln) end
                end
                
                if #valid == 0 then table.insert(valid, (FSM.COPY_MODE == "A") and lines[#lines] or lines[1]) end
            else
                table.insert(valid, (FSM.COPY_MODE == "A") and lines[#lines] or lines[1])
            end
            final_text = table.concat(valid, " ")
        end
    end
    
    if final_text ~= "" then
        local safe_txt = final_text:gsub("'", "''")
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value '%s'", safe_txt)
        utils.subprocess({ args = {"powershell", "-NoProfile", "-Command", cmd}, cancellable = false })
        
        local words, wcount = {}, 0
        for w in final_text:gmatch("%S+") do
            if wcount < Options.copy_word_limit then table.insert(words, w) end
            wcount = wcount + 1
        end
        local osd_t = table.concat(words, " ") .. (wcount > Options.copy_word_limit and "..." or "")
        show_osd("Copied " .. FSM.COPY_MODE .. ": " .. osd_t)
    else
        show_osd("No subtitle to copy")
    end
end

-- =========================================================================
-- SYSTEM EVENTS
-- =========================================================================

mp.observe_property("sid", "number", update_media_state)
mp.observe_property("secondary-sid", "number", update_media_state)
mp.observe_property("track-list", "native", update_media_state)

mp.register_event("shutdown", function()
    if FSM.DRUM == "ON" then
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
    end
end)

-- Register Bindings
mp.add_key_binding(nil, "toggle-autopause", cmd_toggle_autopause)
mp.add_key_binding(nil, "toggle-karaoke-mode", cmd_toggle_karaoke)
mp.add_key_binding(nil, "smart-space", cmd_smart_space, {complex=true})
mp.add_key_binding("c", "toggle-drum-mode", cmd_toggle_drum)
mp.add_key_binding(nil, "toggle-sub-visibility", cmd_toggle_sub_vis)
mp.add_key_binding(nil, "cycle-secondary-pos", cmd_cycle_sec_pos)
mp.add_key_binding(nil, "cycle-sec-sid", cmd_cycle_sec_sid)
mp.add_key_binding(nil, "toggle-osc-visibility", cmd_toggle_osc)
mp.add_key_binding(nil, "copy-subtitle", cmd_copy_sub)
mp.add_key_binding(nil, "cycle-copy-mode", cmd_cycle_copy_mode)
mp.add_key_binding(nil, "toggle-copy-context", cmd_toggle_copy_ctx)
