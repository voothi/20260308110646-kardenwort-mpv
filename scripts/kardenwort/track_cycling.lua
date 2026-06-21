-- ============================================================================
-- track_cycling.lua — Secondary Subtitle and Audio cycling logic
-- ============================================================================

local mp = require("mp")
local companion = require("companion")

local M = {}

local FSM, Options, Tracks, Diagnostic
local _helpers

function M.init(fsm, opts, tracks, diag, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(tracks, "FATAL: tracks dependency missing")
    assert(diag, "FATAL: diag dependency missing")
    assert(helpers, "FATAL: helpers dependency missing")
    assert(helpers.show_osd, "FATAL: helper 'show_osd' missing")
    assert(helpers.drum_osd, "FATAL: helper 'drum_osd' missing")

    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diag
    _helpers = setmetatable(helpers, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end,
    })
end

function M.cmd_cycle_sec_sid()
    if FSM.DRUM_WINDOW ~= "OFF" then
        _helpers.show_osd("X")
        return
    end
    if not FSM.native_sub_vis then
        _helpers.show_osd("X")
        return
    end
    -- Prevent contradictory state overlays: while Secondary Sub Only mode is active,
    -- blocking OFF/cycle on secondary sid keeps the mode deterministic.
    if FSM.SEC_ONLY_MODE then
        _helpers.show_osd("X")
        return
    end
    FSM.native_sec_sub_vis = true
    -- [20260509180045] Synchronous Suppression: Prevent flash of native subs before next tick.
    local use_osd_for_srt = (
        Options.srt_font_name ~= ""
        or Options.srt_font_bold
        or Options.srt_font_size > 0
    )
    local sec_use_osd = (FSM.DRUM == "ON") or (not Tracks.sec.is_ass and use_osd_for_srt)
    if sec_use_osd then
        mp.set_property_bool("secondary-sub-visibility", false)
    else
        mp.set_property_bool("secondary-sub-visibility", true)
    end

    FSM.__auto_track_selected_sec = true

    local tracks = mp.get_property_native("track-list") or {}
    local current_sid = tonumber(mp.get_property("secondary-sid") or 0) or 0
    local primary_sid = tonumber(mp.get_property("sid") or 0) or 0

    -- Filter for supported tracks (External files only)
    local supported = { 0 } -- Always include OFF (0)
    local internal_count = 0
    for _, t in ipairs(tracks) do
        if t.type == "sub" then
            if t.external then
                local tid = tonumber(t.id)
                -- Skip the track that is already selected as primary to avoid conflicts
                if tid and tid ~= primary_sid then
                    table.insert(supported, tid)
                end
            else
                internal_count = internal_count + 1
            end
        end
    end
    table.sort(supported)

    if #supported <= 1 then
        local msg = "Secondary Subtitles: None available"
        if internal_count > 0 then
            msg = msg .. " [" .. internal_count .. " built-in unsupported]"
        end
        _helpers.show_osd(msg)
        mp.set_property("secondary-sid", "no")
        return
    end

    -- Dynamically initialize last_sec_sid and prev_sec_sid history if not set
    if not FSM.last_sec_sid then
        local supported_active = {}
        for _, t in ipairs(tracks) do
            if t.type == "sub" and t.external then
                local tid = tonumber(t.id)
                if tid and tid ~= primary_sid then
                    table.insert(supported_active, tid)
                end
            end
        end
        table.sort(supported_active)
        FSM.last_sec_sid = supported_active[1] or 0
        FSM.prev_sec_sid = supported_active[2] or supported_active[1] or 0
    end

    -- Update history if current active track shifted outside of our script actions
    if current_sid ~= 0 and current_sid ~= FSM.last_sec_sid then
        FSM.prev_sec_sid = FSM.last_sec_sid
        FSM.last_sec_sid = current_sid
    end

    local now = mp.get_time()
    local elapsed = now - (FSM.last_sec_sub_cycle_time or 0)
    local threshold = tonumber(Options.sub_switch_threshold) or 1.0

    local next_sid = 0
    if elapsed > threshold then
        -- Slow tap: toggle behavior
        if FSM.prev_sec_sid == 0 or FSM.prev_sec_sid == FSM.last_sec_sid then
            -- Toggle between active and OFF
            if current_sid == 0 then
                next_sid = FSM.last_sec_sid
            else
                next_sid = 0
            end
        else
            -- Toggle between the last two active tracks
            if current_sid == FSM.last_sec_sid then
                next_sid = FSM.prev_sec_sid
            else
                next_sid = FSM.last_sec_sid
            end
        end
    else
        -- Rapid tap: cycle through all tracks sequentially
        local found = false
        for i = 1, #supported do
            if supported[i] == current_sid then
                next_sid = supported[i % #supported + 1]
                found = true
                break
            end
        end
        if not found then
            next_sid = supported[2] or 0
        end
    end

    FSM.last_sec_sub_cycle_time = now

    -- Validate that chosen next_sid exists in supported list, fallback to supported[2] if not
    local next_sid_valid = false
    for _, sid in ipairs(supported) do
        if sid == next_sid then
            next_sid_valid = true
            break
        end
    end
    if not next_sid_valid then
        next_sid = supported[2] or 0
    end

    if next_sid == 0 then
        mp.set_property("secondary-sid", "no")
    else
        mp.set_property_number("secondary-sid", next_sid)

        -- Update the last active tracks history
        if next_sid ~= FSM.last_sec_sid then
            FSM.prev_sec_sid = FSM.last_sec_sid
            FSM.last_sec_sid = next_sid
        end
    end

    local label = "OFF"
    if next_sid ~= 0 then
        for _, t in ipairs(tracks) do
            if t.type == "sub" and tonumber(t.id) == next_sid then
                local path = t["external-filename"] or t["external_filename"] or ""
                local lang_detected = nil

                if path ~= "" then
                    lang_detected = companion.extract_lang_from_title_or_path(t.title, path)
                end
                if not lang_detected and t.title then
                    lang_detected = companion.extract_lang_from_title_or_path(t.title, nil)
                end

                if lang_detected then
                    label = lang_detected
                else
                    local lang_lbl = (t.lang and t.lang ~= "und" and t.lang ~= "unknown")
                            and t.lang:upper()
                        or nil
                    if lang_lbl then
                        label = lang_lbl
                    else
                        label = t.title or "ON"
                        if label:find("%.") then
                            local base_label = label:match("([^%.]+)%.")
                            if base_label then
                                label = base_label
                            end
                        end
                    end
                end
                break
            end
        end
    end

    local final_msg = "Secondary Sub: " .. label
    if internal_count > 0 then
        final_msg = final_msg .. " [" .. internal_count .. " built-in hidden]"
    end
    _helpers.show_osd(final_msg)
    _helpers.drum_osd:update()
end

function M.cmd_cycle_audio()
    companion.ensure_companion_audio_tracks(mp.get_property("path"))

    local tracks = mp.get_property_native("track-list") or {}
    local current_aid = tonumber(mp.get_property("aid") or 0) or 0
    if current_aid == 0 then
        local aid_str = mp.get_property("aid")
        if aid_str == "no" then
            current_aid = 0
        end
    end

    local supported = { 0 }
    local supported_active = {}
    for _, t in ipairs(tracks) do
        if t.type == "audio" then
            local tid = tonumber(t.id)
            if tid then
                table.insert(supported, tid)
                table.insert(supported_active, tid)
            end
        end
    end
    table.sort(supported)
    table.sort(supported_active)

    if #supported <= 1 then
        _helpers.show_osd("Audio: None available")
        return
    end

    -- Dynamically initialize last_aid and prev_aid history if not set
    if not FSM.last_aid then
        FSM.last_aid = supported_active[1] or 0
        FSM.prev_aid = supported_active[2] or supported_active[1] or 0
    end

    -- Update history if current active track shifted outside of our script actions
    if current_aid ~= 0 and current_aid ~= FSM.last_aid then
        FSM.prev_aid = FSM.last_aid
        FSM.last_aid = current_aid
    end

    local now = mp.get_time()
    local elapsed = now - (FSM.last_audio_cycle_time or 0)
    local threshold = tonumber(Options.audio_switch_threshold) or 1.0

    local next_aid = 0
    if elapsed > threshold then
        -- Slow tap: toggle between last two active tracks
        if current_aid == FSM.last_aid then
            next_aid = FSM.prev_aid
        else
            next_aid = FSM.last_aid
        end
    else
        -- Rapid tap: cycle through all tracks sequentially
        local found = false
        for i = 1, #supported do
            if supported[i] == current_aid then
                next_aid = supported[i % #supported + 1]
                found = true
                break
            end
        end
        if not found then
            next_aid = supported[2] or 0
        end
    end

    if next_aid == 0 then
        mp.set_property("aid", "no")
    else
        mp.set_property_number("aid", next_aid)

        -- Update the last active tracks history
        if next_aid ~= FSM.last_aid then
            FSM.prev_aid = FSM.last_aid
            FSM.last_aid = next_aid
        end
    end

    FSM.last_audio_cycle_time = now

    local label = "OFF"
    if next_aid ~= 0 then
        for _, t in ipairs(tracks) do
            if tonumber(t.id) == next_aid then
                local lang_lbl = (t.lang and t.lang ~= "und" and t.lang ~= "unknown")
                        and t.lang:upper()
                    or nil
                local title_lbl = (t.title and t.title ~= "") and t.title or nil

                if lang_lbl and title_lbl and title_lbl:upper() == lang_lbl then
                    title_lbl = nil
                end

                if (not title_lbl) and t.external then
                    local ext_path = t["external-filename"] or t["external_filename"] or ""
                    if ext_path ~= "" then
                        local ext_file = ext_path:gsub("\\", "/"):match("([^/]+)$") or ""
                        local ext = ext_file:match("%.([^%.]+)$") or ""
                        local ext_stem = ext_file
                        if #ext > 0 then
                            ext_stem = ext_file:sub(1, #ext_file - #ext - 1)
                        end
                        local base_name, postfix =
                            companion.split_base_and_language_postfix(ext_stem)
                        if postfix and base_name and base_name ~= "" then
                            title_lbl = base_name
                        elseif ext_stem ~= "" then
                            title_lbl = ext_stem
                        end
                    end
                end

                if lang_lbl and title_lbl then
                    label = lang_lbl .. " - " .. title_lbl
                elseif lang_lbl then
                    label = lang_lbl
                elseif title_lbl then
                    label = title_lbl
                else
                    label = "TRACK " .. next_aid
                end
                break
            end
        end
    end

    _helpers.show_osd("Audio: " .. label)
end

return M
