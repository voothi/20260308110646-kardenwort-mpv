local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'

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

    -- Toggle Positions
    -- [NOTE] sec_pos_bottom should be ~5% LESS than sub-pos in mpv.conf 
    -- to prevent primary and secondary subtitles from overlapping at the bottom.
    sec_pos_top = 10,
    sec_pos_bottom = 90,

    -- System
    tick_rate = 0.05,
    osd_duration = 1.0,

    -- Drum Window
    dw_font_size = 30,
    dw_lines_visible = 11,        -- how many lines visible in the window
    dw_bg_color = "A9C5D4",       -- beige in BGR hex for ASS
    dw_bg_opacity = "10",         -- background opacity (00-FF, lower is more opaque in ASS alpha? No, 00 is opaque)
    dw_text_color = "1A1A1A",     -- dark text
    dw_active_color = "800000",   -- navy in BGR
    dw_highlight_color = "0000FF", -- red highlight in BGR
    dw_scroll_return_sec = 3.0    -- seconds before auto-returning to center
}
options.read_options(Options, "lls")

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
    native_sec_sub_vis = true,
    native_sec_sub_pos = mp.get_property_number("secondary-sub-pos", 10),

    -- Drum Window State
    DRUM_WINDOW = "OFF",       -- OFF, DOCKED, DETACHED
    DW_CURSOR_LINE = -1,       -- Current line focused by word nav
    DW_CURSOR_WORD = -1,       -- Word index in the current line
    DW_ANCHOR_LINE = -1,       -- Shift-anchor line index
    DW_ANCHOR_WORD = -1,       -- Shift-anchor word index
    DW_SCROLL_OFFSET = 0,      -- Manual scroll offset (lines)
    DW_RETURN_TIMER = nil,     -- Timer to return scroll to zero
    DW_KEY_OVERRIDE = false    -- Are we overriding arrow keys?
}

local Tracks = {
    pri = { id = 0, is_ass = false, path = nil, subs = {} },
    sec = { id = 0, is_ass = false, path = nil, subs = {} }
}

-- UI State pointers for Drum Mode OSD
local drum_osd = mp.create_osd_overlay("ass-events")
drum_osd.res_x = 1920
drum_osd.res_y = 1080

local dw_osd = mp.create_osd_overlay("ass-events")
dw_osd.res_x = 1920
dw_osd.res_y = 1080

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

local function build_word_list(text)
    local words = {}
    for w in text:gmatch("%S+") do
        table.insert(words, w)
    end
    return words
end

-- =========================================================================
-- FSM INTERNAL LOGIC
-- =========================================================================

local function update_media_state()
    Tracks.pri.id = mp.get_property_number("sid", 0)
    Tracks.sec.id = mp.get_property_number("secondary-sid", 0)
    
    local old_pri_path = Tracks.pri.path
    local old_sec_path = Tracks.sec.path

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

    -- Flush stale drum subs when track path changed or track was disabled
    if Tracks.pri.path ~= old_pri_path then Tracks.pri.subs = {} end
    if Tracks.sec.path ~= old_sec_path then Tracks.sec.subs = {} end

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
            mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
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

local function draw_dw(subs, center_idx, time_pos)
    if not subs or #subs == 0 then return "" end
    
    local ass = ""
    local win_lines = Options.dw_lines_visible
    local half_win = math.floor(win_lines / 2)
    
    local effective_center = center_idx + FSM.DW_SCROLL_OFFSET
    effective_center = math.max(1, math.min(#subs, effective_center))
    
    local start_idx = math.max(1, effective_center - half_win)
    local end_idx = math.min(#subs, start_idx + win_lines - 1)
    
    -- Background: Opaque beige panel
    local bg_alpha = Options.dw_bg_opacity -- e.g. "10"
    local bg_color = Options.dw_bg_color   -- e.g. "A9C5D4"
    ass = ass .. string.format("{\\an5}{\\bord0}{\\shad0}{\\alpha&H%s&}{\\c&H%s&}{\\p1}m 0 0 l 1920 0 1920 1080 0 1080{\\p0}\n", bg_alpha, bg_color)
    
    -- Selection points
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    local has_selection = (al ~= -1 and cl ~= -1)
    local p1_l, p1_w, p2_l, p2_w
    if has_selection then
        if al < cl or (al == cl and aw <= cw) then
            p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
        else
            p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
        end
    end

    -- Text Block
    local lines_ass = {}
    for i = start_idx, end_idx do
        local is_active = (i == center_idx)
        local text = subs[i].text:gsub("\n", " ")
        local color = is_active and Options.dw_active_color or Options.dw_text_color
        local line_prefix = string.format("{\\c&H%s&}", color)
        
        local words = build_word_list(text)
        local formatted_words = {}
        
        for j, w in ipairs(words) do
            local selected = false
            if has_selection then
                if i > p1_l and i < p2_l then selected = true
                elseif i == p1_l and i == p2_l then selected = (j >= p1_w and j <= p2_w)
                elseif i == p1_l then selected = (j >= p1_w)
                elseif i == p2_l then selected = (j <= p2_w) end
            elseif i == cl and j == cw then
                -- Single cursor highlight (red)
                table.insert(formatted_words, string.format("{\\c&H%s&}%s{\\c&H%s&}", Options.dw_highlight_color, w, color))
                goto next_word
            end
            
            if selected then
                table.insert(formatted_words, string.format("{\\c&H%s&}%s{\\c&H%s&}", Options.dw_highlight_color, w, color))
            else
                table.insert(formatted_words, w)
            end
            ::next_word::
        end
        
        local line_content = #formatted_words > 0 and table.concat(formatted_words, " ") or text
        table.insert(lines_ass, line_prefix .. line_content)
    end
    
    -- Render the whole block centered
    local block_text = table.concat(lines_ass, "\\N\\N") -- Double \N for extra spacing
    ass = ass .. string.format("{\\pos(960, 540)}{\\an5}{\\bord0}{\\shad0}{\\blur0}{\\alpha&H00&}{\\q0}{\\fs%d}%s", 
        Options.dw_font_size, block_text)
    
    return ass
end

local function tick_dw(time_pos)
    local subs = Tracks.pri.subs
    if #subs == 0 then return end
    
    local idx = get_center_index(subs, time_pos)
    if idx == -1 then return end
    
    -- Sync navigation cursor to active line if it hasn't been manually moved away
    -- or if the user is seeking (A/D)
    if FSM.DW_CURSOR_LINE == -1 then
        FSM.DW_CURSOR_LINE = idx
    end
    
    dw_osd.data = draw_dw(subs, idx, time_pos)
    dw_osd:update()
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
    local sec_pos = FSM.native_sec_sub_pos
    
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

    -- Execute Drum Window
    if FSM.DRUM_WINDOW == "DOCKED" then
        tick_dw(time_pos)
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
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Drum Mode: No subtitles loaded")
        return
    end
    if FSM.MEDIA_STATE:match("ASS") then
        show_osd("Drum Mode: NOT SUPPORTED (ASS Track)", Options.osd_duration + 1.0)
        return
    end

    if FSM.DRUM == "OFF" then
        FSM.DRUM = "ON"
        FSM.native_sub_vis = mp.get_property_bool("sub-visibility", true)
        FSM.native_sec_sub_vis = mp.get_property_bool("secondary-sub-visibility", true)
        FSM.native_sec_sub_pos = mp.get_property_number("secondary-sub-pos", 10)
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
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
        drum_osd.data = ""
        drum_osd:update()
        show_osd("Drum Mode: OFF")
    end
end


local function manage_dw_bindings(enable)
    local keys = {
        {key = "LEFT", name = "dw-word-left", fn = function() cmd_dw_word_move(-1, false) end},
        {key = "RIGHT", name = "dw-word-right", fn = function() cmd_dw_word_move(1, false) end},
        {key = "UP", name = "dw-line-up", fn = function() cmd_dw_line_move(-1, false) end},
        {key = "DOWN", name = "dw-line-down", fn = function() cmd_dw_line_move(1, false) end},
        {key = "Shift+UP", name = "dw-line-up-shift", fn = function() cmd_dw_line_move(-1, true) end},
        {key = "Shift+DOWN", name = "dw-line-down-shift", fn = function() cmd_dw_line_move(1, true) end},
        {key = "a", name = "dw-seek-back", fn = function() 
            mp.command("sub-seek -1") 
            mp.add_timeout(0.05, function() FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, mp.get_property_number("time-pos")) end)
        end},
        {key = "d", name = "dw-seek-fwd", fn = function() 
            mp.command("sub-seek 1") 
            mp.add_timeout(0.05, function() FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, mp.get_property_number("time-pos")) end)
        end},
        {key = "Shift+LEFT", name = "dw-word-left-shift", fn = function() cmd_dw_word_move(-1, true) end},
        {key = "Shift+RIGHT", name = "dw-word-right-shift", fn = function() cmd_dw_word_move(1, true) end},
        {key = "WHEEL_UP", name = "dw-scroll-up", fn = function() cmd_dw_scroll(-1) end},
        {key = "WHEEL_DOWN", name = "dw-scroll-down", fn = function() cmd_dw_scroll(1) end},
        {key = "ESC", name = "dw-close", fn = function() cmd_toggle_drum_window() end},
        {key = "Ctrl+c", name = "dw-copy", fn = function() cmd_dw_copy() end},
         -- RU Layout
        {key = "ЛЕВЫЙ", name = "dw-word-left-ru", fn = function() cmd_dw_word_move(-1, false) end},
        {key = "ПРАВЫЙ", name = "dw-word-right-ru", fn = function() cmd_dw_word_move(1, false) end},
        {key = "ВВЕРХ", name = "dw-line-up-ru", fn = function() cmd_dw_line_move(-1, false) end},
        {key = "ВНИЗ", name = "dw-line-down-ru", fn = function() cmd_dw_line_move(1, false) end},
        {key = "Shift+ЛЕВЫЙ", name = "dw-word-left-shift-ru", fn = function() cmd_dw_word_move(-1, true) end},
        {key = "Shift+ПРАВЫЙ", name = "dw-word-right-shift-ru", fn = function() cmd_dw_word_move(1, true) end},
        {key = "Shift+ВВЕРХ", name = "dw-line-up-shift-ru", fn = function() cmd_dw_line_move(-1, true) end},
        {key = "Shift+ВНИЗ", name = "dw-line-down-shift-ru", fn = function() cmd_dw_line_move(1, true) end},
        {key = "ф", name = "dw-seek-back-ru", fn = function() 
            mp.command("sub-seek -1") 
            mp.add_timeout(0.05, function() FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, mp.get_property_number("time-pos")) end)
        end},
        {key = "в", name = "dw-seek-fwd-ru", fn = function() 
            mp.command("sub-seek 1") 
            mp.add_timeout(0.05, function() FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, mp.get_property_number("time-pos")) end)
        end},
        {key = "Ctrl+с", name = "dw-copy-ru", fn = function() cmd_dw_copy() end}
    }
    
    for _, k in ipairs(keys) do
        if enable then 
            local settings = nil
            if k.key:match("LEFT") or k.key:match("RIGHT") or k.key:match("UP") or k.key:match("DOWN") 
               or k.key:match("ЛЕВЫЙ") or k.key:match("ПРАВЫЙ") or k.key:match("ВВЕРХ") or k.key:match("ВНИЗ")
               or k.key == "a" or k.key == "d" or k.key == "ф" or k.key == "в" then
                settings = "repeatable"
            end
            mp.add_forced_key_binding(k.key, k.name, k.fn, settings)
        else mp.remove_key_binding(k.name) end
    end
    FSM.DW_KEY_OVERRIDE = enable
end

function cmd_toggle_drum_window()
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Drum Window: No subtitles loaded")
        return
    end

    if FSM.DRUM_WINDOW == "OFF" then
        FSM.DRUM_WINDOW = "DOCKED"
        
        -- Boot subs for memory if haven't already
        if Tracks.pri.path and #Tracks.pri.subs == 0 then
            Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
        end
        
        local time_pos = mp.get_property_number("time-pos")
        FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, time_pos)
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_SCROLL_OFFSET = 0
        
        manage_dw_bindings(true)
        show_osd("Drum Window: OPEN")
    else
        FSM.DRUM_WINDOW = "OFF"
        manage_dw_bindings(false)
        dw_osd.data = ""
        dw_osd:update()
        show_osd("Drum Window: CLOSED")
    end
end

function cmd_dw_scroll(dir)
    FSM.DW_SCROLL_OFFSET = FSM.DW_SCROLL_OFFSET + dir
    
    if FSM.DW_RETURN_TIMER then FSM.DW_RETURN_TIMER:kill() end
    FSM.DW_RETURN_TIMER = mp.add_timeout(Options.dw_scroll_return_sec, function()
        FSM.DW_SCROLL_OFFSET = 0
    end)
end

function cmd_dw_line_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = (FSM.DW_CURSOR_WORD > 0) and FSM.DW_CURSOR_WORD or 1
    end
    
    FSM.DW_CURSOR_LINE = math.max(1, math.min(#subs, FSM.DW_CURSOR_LINE + dir))
    
    if not shift then
        FSM.DW_CURSOR_WORD = 1 -- Highlight first word
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    else
        -- When moving lines with shift, we typically want to stay at word 1 
        -- or similar to capture the whole line start/end.
        if FSM.DW_CURSOR_WORD == -1 then FSM.DW_CURSOR_WORD = 1 end
    end
end

function cmd_dw_word_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local text = subs[FSM.DW_CURSOR_LINE].text:gsub("\n", " ")
    local words = build_word_list(text)
    
    if FSM.DW_CURSOR_WORD == -1 then
        FSM.DW_CURSOR_WORD = (dir > 0) and 1 or #words
    else
        FSM.DW_CURSOR_WORD = FSM.DW_CURSOR_WORD + dir
    end
    
    -- Handle wrap-around lines
    if FSM.DW_CURSOR_WORD < 1 then
        if FSM.DW_CURSOR_LINE > 1 then
            FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE - 1
            local next_text = subs[FSM.DW_CURSOR_LINE].text:gsub("\n", " ")
            local next_words = build_word_list(next_text)
            FSM.DW_CURSOR_WORD = #next_words
        else
            FSM.DW_CURSOR_WORD = 1
        end
    elseif FSM.DW_CURSOR_WORD > #words then
        if FSM.DW_CURSOR_LINE < #subs then
            FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE + 1
            FSM.DW_CURSOR_WORD = 1
        else
            FSM.DW_CURSOR_WORD = #words
        end
    end
    
    if not shift then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    elseif FSM.DW_ANCHOR_WORD == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD - dir -- anchor where we started
    end
end

function cmd_dw_copy()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    
    local final_text = ""
    
    if al ~= -1 and aw ~= -1 and cl ~= -1 and cw ~= -1 then
        -- Range selection
        local p1_l, p1_w, p2_l, p2_w
        if al < cl or (al == cl and aw <= cw) then
            p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
        else
            p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
        end
        
        local parts = {}
        for i = p1_l, p2_l do
            local text = subs[i].text:gsub("\n", " ")
            local words = build_word_list(text)
            local line_words = {}
            local s_w = (i == p1_l) and p1_w or 1
            local e_w = (i == p2_l) and p2_w or #words
            
            for j = s_w, e_w do
                table.insert(line_words, words[j])
            end
            if #line_words > 0 then
                table.insert(parts, table.concat(line_words, " "))
            end
        end
        final_text = table.concat(parts, " ")
    else
        -- Single point or line fallback
        local text = subs[FSM.DW_CURSOR_LINE].text:gsub("\n", " ")
        if FSM.DW_CURSOR_WORD > 0 then
            local words = build_word_list(text)
            final_text = words[FSM.DW_CURSOR_WORD] or text
        else
            final_text = text
        end
    end
    
    if final_text ~= "" then
        final_text = final_text:gsub("{[^}]+}", "")
        local safe_txt = final_text:gsub("'", "''")
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value '%s'", safe_txt)
        utils.subprocess({ args = {"powershell", "-NoProfile", "-Command", cmd}, cancellable = false })
        show_osd("DW Copied: " .. final_text:sub(1, 30) .. (#final_text > 30 and "..." or ""))
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
    if Tracks.sec.id == 0 then
        show_osd("Secondary Sub Pos: No secondary subtitle loaded")
        return
    end
    if Tracks.sec.is_ass then
        show_osd("Secondary Sub Pos: Not available (ASS controls positioning)")
        return
    end
    if FSM.DRUM == "ON" then
        FSM.native_sec_sub_pos = (FSM.native_sec_sub_pos < 50) and Options.sec_pos_bottom or Options.sec_pos_top
        show_osd("Secondary Sub Pos: " .. ((FSM.native_sec_sub_pos < 50) and "TOP" or "BOTTOM"))
    else
        local p = mp.get_property_number("secondary-sub-pos", Options.sec_pos_top)
        local n = (p < 50) and Options.sec_pos_bottom or Options.sec_pos_top
        mp.set_property_number("secondary-sub-pos", n)
        show_osd("Secondary Sub Pos: " .. ((n < 50) and "TOP" or "BOTTOM"))
    end
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
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Copy Mode: No subtitles loaded")
        return
    end
    if FSM.MEDIA_STATE == "SINGLE_SRT" then
        show_osd("Copy Mode: Only available with ASS or dual subtitles")
        return
    end
    FSM.COPY_MODE = (FSM.COPY_MODE == "A") and "B" or "A"
    show_osd("Copy Subtitle Mode: " .. FSM.COPY_MODE)
end

local function cmd_toggle_copy_ctx()
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Context Copy: No subtitles loaded")
        return
    end
    if not Tracks.pri.path and not Tracks.sec.path then
        show_osd("Context Copy: Requires external subtitle files")
        return
    end
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
                if Options.copy_filter_russian and not is_target(trim(subs[idx].text)) then
                    if idx > 1 and subs[idx-1].start_time == subs[idx].start_time and is_target(trim(subs[idx-1].text)) then
                        idx = idx - 1
                    elseif idx < #subs and subs[idx+1].start_time == subs[idx].start_time and is_target(trim(subs[idx+1].text)) then
                        idx = idx + 1
                    end
                end
                
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
    if FSM.DRUM == "ON" or FSM.DRUM_WINDOW == "DOCKED" then
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
        manage_dw_bindings(false)
    end
end)

-- Register Bindings
mp.add_key_binding(nil, "toggle-autopause", cmd_toggle_autopause)
mp.add_key_binding(nil, "toggle-karaoke-mode", cmd_toggle_karaoke)
mp.add_key_binding(nil, "smart-space", cmd_smart_space, {complex=true})
mp.add_key_binding(nil, "toggle-drum-mode", cmd_toggle_drum)
mp.add_key_binding(nil, "toggle-sub-visibility", cmd_toggle_sub_vis)
mp.add_key_binding(nil, "cycle-secondary-pos", cmd_cycle_sec_pos)
mp.add_key_binding(nil, "cycle-sec-sid", cmd_cycle_sec_sid)
mp.add_key_binding(nil, "toggle-osc-visibility", cmd_toggle_osc)
mp.add_key_binding(nil, "copy-subtitle", cmd_copy_sub)
mp.add_key_binding(nil, "cycle-copy-mode", cmd_cycle_copy_mode)
mp.add_key_binding(nil, "toggle-copy-context", cmd_toggle_copy_ctx)
mp.add_key_binding(nil, "toggle-drum-window", cmd_toggle_drum_window)
