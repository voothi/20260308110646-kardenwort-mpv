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
    dw_highlight_color = "0000FF",-- red highlight in BGR
    dw_font_name = "Consolas",    -- monospace font for perfect hit-testing
    dw_char_width = 0.55          -- char width multiplier (0.55 is exact for Consolas)
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
    native_sub_vis = mp.get_property_bool("sub-visibility", true),
    native_sec_sub_vis = mp.get_property_bool("secondary-sub-visibility", true),
    native_sec_sub_pos = mp.get_property_number("secondary-sub-pos", 10),

    -- Drum Window State
    DRUM_WINDOW = "OFF",       -- OFF, DOCKED, DETACHED
    DW_CURSOR_LINE = -1,       -- Current line focused by word nav
    DW_CURSOR_WORD = -1,       -- Word index in the current line
    DW_ANCHOR_LINE = -1,       -- Shift-anchor line index
    DW_ANCHOR_WORD = -1,       -- Shift-anchor word index
    DW_VIEW_CENTER = -1,       -- Viewport center line index
    DW_FOLLOW_PLAYER = true,   -- Follow active playback line?
    DW_KEY_OVERRIDE = false,   -- Are we overriding arrow keys?
    DW_MOUSE_DRAGGING = false, -- True while LMB is held and dragging
    DW_MOUSE_SCROLL_TIMER = nil, -- Timer for auto-scroll while dragging at edges

    -- Global Search State
    SEARCH_MODE = false,
    SEARCH_QUERY = "",
    SEARCH_RESULTS = {},
    SEARCH_SEL_IDX = 1,
    SEARCH_CURSOR = 0,
    SEARCH_ANCHOR = -1
}

local Tracks = {
    pri = { id = 0, is_ass = false, path = nil, subs = {} },
    sec = { id = 0, is_ass = false, path = nil, subs = {} }
}

-- UI State pointers for Drum Mode OSD
local drum_osd = mp.create_osd_overlay("ass-events")
drum_osd.res_x = 1920
drum_osd.res_y = 1080
drum_osd.z = 10

local dw_osd = mp.create_osd_overlay("ass-events")
dw_osd.res_x = 1920
dw_osd.res_y = 1080
dw_osd.z = 20

local search_osd = mp.create_osd_overlay("ass-events")
search_osd.res_x = 1920
search_osd.res_y = 1080
search_osd.z = 30

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
        local ms_val = tonumber(ms)
        if #ms == 2 then ms_val = ms_val * 10 end -- Centiseconds to milliseconds
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + ms_val / 1000
    end
    return 0
end

local function utf8_to_table(str)
    local t = {}
    for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(t, ch)
    end
    return t
end

local function get_word_boundary(q_table, pos, direction)
    -- direction: -1 (left), 1 (right)
    if #q_table == 0 then return 0 end
    
    local new_pos = pos
    local function is_word_char(ch)
        if not ch then return false end
        -- Basic alphanumeric + Cyrillic
        return ch:match("[%w\128-\255]") ~= nil
    end

    if direction == -1 then
        -- Skip spaces to the left
        while new_pos > 0 and not is_word_char(q_table[new_pos]) do
            new_pos = new_pos - 1
        end
        -- Skip word chars to the left
        while new_pos > 0 and is_word_char(q_table[new_pos]) do
            new_pos = new_pos - 1
        end
    else
        -- Skip spaces to the right
        while new_pos < #q_table and not is_word_char(q_table[new_pos + 1]) do
            new_pos = new_pos + 1
        end
        -- Skip word chars to the right
        while new_pos < #q_table and is_word_char(q_table[new_pos + 1]) do
            new_pos = new_pos + 1
        end
    end
    
    return new_pos
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

-- Helper to estimate the width of a proportional string
local function dw_get_str_width(str)
    local char_w = Options.dw_font_size * Options.dw_char_width
    if Options.dw_font_name:lower():match("consolas") or Options.dw_font_name:lower():match("mono") then
        local len = 0
        for _ in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do len = len + 1 end
        return len * char_w
    end
    
    local fs = Options.dw_font_size
    local w = 0
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if c == " " then w = w + (fs * 0.35)
        elseif c:match("[il1tI|!.,:;'\"`%(%)%[%]]") then w = w + (fs * 0.25)
        elseif c:match("[mwMW%@]") then w = w + (fs * 0.70)
        elseif c:match("[a-zA-Z0-9]") then w = w + (fs * 0.45)
        elseif #c > 1 then w = w + (fs * 0.50)
        else w = w + (fs * 0.45) end
    end
    return w
end

-- Unified layout engine: wraps subtitle words into visual lines
local function dw_build_layout(subs, view_center)
    local win_lines = Options.dw_lines_visible
    local half_win = math.floor(win_lines / 2)
    view_center = math.max(1, math.min(#subs, view_center))
    local start_idx = math.max(1, view_center - half_win)
    local end_idx = math.min(#subs, start_idx + win_lines - 1)

    local vline_h = Options.dw_font_size * 1.0
    local sub_gap = Options.dw_font_size * 0.6
    local max_text_w = 1860
    local space_w = dw_get_str_width(" ")

    local layout = {}
    local total_height = 0

    for i = start_idx, end_idx do
        local text = subs[i].text:gsub("\n", " ")
        local words = build_word_list(text)
        if #words == 0 then words = {""} end

        local vlines = {}
        local cur_indices = {}
        local cur_w = 0

        for j, w in ipairs(words) do
            local ww = dw_get_str_width(w)
            local space = (#cur_indices > 0) and space_w or 0
            if cur_w + space + ww > max_text_w and #cur_indices > 0 then
                table.insert(vlines, cur_indices)
                cur_indices = {j}
                cur_w = ww
            else
                table.insert(cur_indices, j)
                cur_w = cur_w + space + ww
            end
        end
        if #cur_indices > 0 then table.insert(vlines, cur_indices) end
        if #vlines == 0 then vlines = {{1}} end

        local entry_h = #vlines * vline_h
        table.insert(layout, {
            sub_idx = i,
            words = words,
            vlines = vlines,
            height = entry_h
        })
        total_height = total_height + entry_h
        if i < end_idx then total_height = total_height + sub_gap end
    end

    return layout, total_height
end

-- draw_dw: view_center = which line is in the center of the viewport
--          active_idx = which line is currently playing (colored blue, may be off-screen)
local function draw_dw(subs, view_center, active_idx)
    if not subs or #subs == 0 then return "" end
    
    local ass = ""
    local layout, _ = dw_build_layout(subs, view_center)
    
    -- Background: Opaque beige panel
    local bg_alpha = Options.dw_bg_opacity
    local bg_color = Options.dw_bg_color
    ass = ass .. string.format("{\\an5}{\\bord0}{\\shad0}{\\alpha&H%s&}{\\c&H%s&}{\\p1}m 0 0 l 1920 0 1920 1080 0 1080{\\p0}\n", bg_alpha, bg_color)
    
    -- Selection range
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    local has_selection = (al ~= -1 and aw ~= -1)
    local p1_l, p1_w, p2_l, p2_w
    if has_selection then
        if al < cl or (al == cl and aw <= cw) then
            p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
        else
            p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
        end
    end

    -- Text Block mapping
    local lines_ass = {}
    for _, entry in ipairs(layout) do
        local i = entry.sub_idx
        local is_active = (i == active_idx)
        local color = is_active and Options.dw_active_color or Options.dw_text_color
        local line_prefix = string.format("{\\fn%s}{\\c&H%s&}", Options.dw_font_name, color)
        
        local entry_ass_vlines = {}
        for _, vl_indices in ipairs(entry.vlines) do
            local formatted_words = {}
            for _, j in ipairs(vl_indices) do
                local w = entry.words[j]
                local selected = false
                if has_selection then
                    if i > p1_l and i < p2_l then selected = true
                    elseif i == p1_l and i == p2_l then selected = (j >= p1_w and j <= p2_w)
                    elseif i == p1_l then selected = (j >= p1_w)
                    elseif i == p2_l then selected = (j <= p2_w) end
                elseif i == cl and j == cw then
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
            table.insert(entry_ass_vlines, table.concat(formatted_words, " "))
        end
        -- Join visual lines for this subtitle with ONE \N (soft wrap within the same subtitle)
        table.insert(lines_ass, line_prefix .. table.concat(entry_ass_vlines, "\\N"))
    end
    
    -- Join separate subtitles with \N\N
    local block_text = table.concat(lines_ass, "\\N\\N")
    -- \q2 disables smart wrapping: forces screen layout to exactly match our dw_build_layout
    ass = ass .. string.format("{\\pos(960, 540)}{\\an5}{\\bord0}{\\shad0}{\\blur0}{\\alpha&H00&}{\\q2}{\\fs%d}%s", 
        Options.dw_font_size, block_text)
    
    return ass
end

-- =========================================================================
-- DRUM WINDOW MOUSE SELECTION
-- =========================================================================

local function dw_get_mouse_osd()
    local mouse = mp.get_property_native("mouse-pos")
    if not mouse then return 960, 540 end
    local mx = mouse.x or 0
    local my = mouse.y or 0
    local osd = mp.get_property_native("osd-dimensions")
    local ow = osd and osd.w or 1920
    local oh = osd and osd.h or 1080
    if ow == 0 then ow = 1920 end
    if oh == 0 then oh = 1080 end
    -- Scale from actual window pixels to OSD resolution (1920x1080)
    local osd_x = (mx / ow) * 1920
    local osd_y = (my / oh) * 1080
    return osd_x, osd_y
end

local function dw_hit_test(osd_x, osd_y)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return nil, nil end

    local layout, total_height = dw_build_layout(subs, FSM.DW_VIEW_CENTER)

    local vline_h = Options.dw_font_size * 1.0
    local sub_gap = Options.dw_font_size * 0.6
    local space_w = dw_get_str_width(" ")

    local block_top = 540 - total_height / 2

    -- Clamp vertically to the first/last word if outside the entire block
    if osd_y <= block_top then
        local first = layout[1]
        return first.sub_idx, first.vlines[1][1]
    end
    if osd_y >= block_top + total_height then
        local last = layout[#layout]
        local last_vl = last.vlines[#last.vlines]
        return last.sub_idx, last_vl[#last_vl]
    end

    local y_pos = block_top
    for _, entry in ipairs(layout) do
        local entry_bottom = y_pos + entry.height
        -- If osd_y is within the entry OR in the gap immediately below it, snap it to this entry
        if osd_y < entry_bottom + sub_gap then
            local rel_y = math.max(0, math.min(osd_y - y_pos, entry.height - 0.001))
            local vl_num = math.floor(rel_y / vline_h) + 1
            vl_num = math.max(1, math.min(#entry.vlines, vl_num))

            local vl_indices = entry.vlines[vl_num]

            local vl_width = 0
            for k, wi in ipairs(vl_indices) do
                vl_width = vl_width + dw_get_str_width(entry.words[wi])
                if k < #vl_indices then vl_width = vl_width + space_w end
            end
            
            local vl_left = 960 - vl_width / 2

            local cx = osd_x - vl_left
            if cx < 0 then return entry.sub_idx, vl_indices[1] end
            if cx >= vl_width then return entry.sub_idx, vl_indices[#vl_indices] end

            -- Build word center positions for snap-to-nearest logic
            local centers = {}
            local pos = 0
            for k, wi in ipairs(vl_indices) do
                local ww = dw_get_str_width(entry.words[wi])
                centers[k] = { idx = wi, center = pos + ww / 2 }
                pos = pos + ww + space_w
            end
            -- Find the word whose center is closest to the cursor
            local best_k = 1
            local best_dist = math.abs(cx - centers[1].center)
            for k = 2, #centers do
                local dist = math.abs(cx - centers[k].center)
                if dist < best_dist then
                    best_dist = dist
                    best_k = k
                end
            end
            return entry.sub_idx, centers[best_k].idx
        end
        y_pos = entry_bottom + sub_gap
    end

    -- Fallback safety, should never be reached due to the >= check at the top
    local last = layout[#layout]
    local last_vl = last.vlines[#last.vlines]
    return last.sub_idx, last_vl[#last_vl]
end

local function dw_mouse_update_selection()
    if not FSM.DW_MOUSE_DRAGGING then return end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx = dw_hit_test(osd_x, osd_y)

    if line_idx and word_idx then
        FSM.DW_CURSOR_LINE = line_idx
        FSM.DW_CURSOR_WORD = word_idx
        dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, get_center_index(subs, mp.get_property_number("time-pos") or 0))
        dw_osd:update()
    end
end

local function dw_mouse_auto_scroll()
    if not FSM.DW_MOUSE_DRAGGING then return end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local _, osd_y = dw_get_mouse_osd()

    local edge_zone = 1080 * 0.15
    local scrolled = false
    if osd_y < edge_zone then
        if FSM.DW_VIEW_CENTER > 1 then
            FSM.DW_VIEW_CENTER = FSM.DW_VIEW_CENTER - 1
            if FSM.DW_CURSOR_LINE > 1 then FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE - 1 end
            scrolled = true
        end
    elseif osd_y > 1080 - edge_zone then
        if FSM.DW_VIEW_CENTER < #subs then
            FSM.DW_VIEW_CENTER = FSM.DW_VIEW_CENTER + 1
            if FSM.DW_CURSOR_LINE < #subs then FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE + 1 end
            scrolled = true
        end
    end
    
    if scrolled then
        -- Force re-evaluate mouse position on new scroll anchor
        dw_mouse_update_selection()
    end
end

local function make_mouse_handler(is_shift)
    return function(tbl)
        if tbl.event == "down" then
            FSM.DW_FOLLOW_PLAYER = false

            local osd_x, osd_y = dw_get_mouse_osd()
            local line_idx, word_idx = dw_hit_test(osd_x, osd_y)

            if line_idx and word_idx then
                if is_shift then
                    if FSM.DW_ANCHOR_LINE == -1 then
                        -- Start shift selection from the current cursor position
                        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
                        FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
                    end
                    -- Extend selection to the clicked word
                    FSM.DW_CURSOR_LINE = line_idx
                    FSM.DW_CURSOR_WORD = word_idx
                else
                    -- Normal click: set both anchor and cursor
                    FSM.DW_CURSOR_LINE = line_idx
                    FSM.DW_CURSOR_WORD = word_idx
                    FSM.DW_ANCHOR_LINE = line_idx
                    FSM.DW_ANCHOR_WORD = word_idx
                end
                
                FSM.DW_MOUSE_DRAGGING = true
                
                -- Fast-tracking on mouse move
                mp.add_forced_key_binding("mouse_move", "dw-mouse-drag", dw_mouse_update_selection)

                -- Start a repeating timer for auto-scroll near edges
                if FSM.DW_MOUSE_SCROLL_TIMER then
                    FSM.DW_MOUSE_SCROLL_TIMER:kill()
                end
                FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(0.05, dw_mouse_auto_scroll)
            end
        elseif tbl.event == "up" then
            FSM.DW_MOUSE_DRAGGING = false
            mp.remove_key_binding("dw-mouse-drag")
            if FSM.DW_MOUSE_SCROLL_TIMER then
                FSM.DW_MOUSE_SCROLL_TIMER:kill()
                FSM.DW_MOUSE_SCROLL_TIMER = nil
            end

            -- If anchor equals cursor and we weren't shift-clicking, clear selection (single click = just cursor)
            if not is_shift and FSM.DW_ANCHOR_LINE == FSM.DW_CURSOR_LINE and FSM.DW_ANCHOR_WORD == FSM.DW_CURSOR_WORD then
                FSM.DW_ANCHOR_LINE = -1
                FSM.DW_ANCHOR_WORD = -1
            end
        end
    end
end

local cmd_dw_mouse_handler = make_mouse_handler(false)
local cmd_dw_mouse_shift_handler = make_mouse_handler(true)

local function cmd_dw_double_click()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx = dw_hit_test(osd_x, osd_y)
    if not line_idx then return end

    local sub = subs[line_idx]
    if sub and sub.start_time then
        mp.commandv("seek", sub.start_time, "absolute+exact")
        FSM.DW_CURSOR_LINE = line_idx
        FSM.DW_CURSOR_WORD = word_idx or 1
        FSM.DW_VIEW_CENTER = line_idx
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    end
end

local function tick_dw(time_pos)
    local subs = Tracks.pri.subs
    if #subs == 0 then return end
    
    local active_idx = get_center_index(subs, time_pos)
    if active_idx == -1 then return end
    
    -- In follow mode: viewport and cursor track the active playback line
    if FSM.DW_FOLLOW_PLAYER then
        FSM.DW_VIEW_CENTER = active_idx
        FSM.DW_CURSOR_LINE = active_idx
    end
    -- In manual mode: DW_VIEW_CENTER and DW_CURSOR_LINE are frozen,
    -- active_idx just controls the blue highlight color (may be off-screen)
    
    dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
    dw_osd:update()
end

local function tick_drum(time_pos)
    -- Don't render Drum Mode OSD while Drum Window is open (they overlap)
    if FSM.DRUM_WINDOW ~= "OFF" then return end
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
    
    local sub_end = mp.get_property_number("sub-end")
    if sub_end == nil or (sub_end - time_pos) >= Options.pause_padding or (sub_end - time_pos) <= 0 then
        return
    end

    if FSM.last_paused_sub_end == sub_end then return end

    local raw_text_primary = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass") or ""
    local raw_text_secondary = mp.get_property("secondary-sub-text") or ""
    
    if raw_text_primary == "" and raw_text_secondary == "" then return end

    if FSM.KARAOKE == "PHRASE" then
        local has_karaoke = string.find(raw_text_primary, Options.karaoke_token, 1, true)
        if not has_karaoke then has_karaoke = string.find(raw_text_secondary, Options.karaoke_token, 1, true) end
        if has_karaoke then return end
    end

    mp.set_property_bool("pause", true)
    FSM.last_paused_sub_end = sub_end
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
            FSM.DW_FOLLOW_PLAYER = true
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_WORD = 1
        end},
        {key = "d", name = "dw-seek-fwd", fn = function() 
            mp.command("sub-seek 1")
            FSM.DW_FOLLOW_PLAYER = true
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_WORD = 1
        end},
        {key = "ENTER", name = "dw-enter", fn = function() cmd_dw_seek_selected() end},
        {key = "KP_ENTER", name = "dw-enter-kp", fn = function() cmd_dw_seek_selected() end},
        {key = "Shift+LEFT", name = "dw-word-left-shift", fn = function() cmd_dw_word_move(-1, true) end},
        {key = "Shift+RIGHT", name = "dw-word-right-shift", fn = function() cmd_dw_word_move(1, true) end},
        {key = "Ctrl+LEFT", name = "dw-word-left-ctrl", fn = function() cmd_dw_word_move(-5, false) end},
        {key = "Ctrl+RIGHT", name = "dw-word-right-ctrl", fn = function() cmd_dw_word_move(5, false) end},
        {key = "Ctrl+Shift+LEFT", name = "dw-word-left-ctrl-shift", fn = function() cmd_dw_word_move(-5, true) end},
        {key = "Ctrl+Shift+RIGHT", name = "dw-word-right-ctrl-shift", fn = function() cmd_dw_word_move(5, true) end},
        {key = "Ctrl+Shift+UP", name = "dw-line-up-ctrl-shift", fn = function() cmd_dw_line_move(-5, true) end},
        {key = "Ctrl+Shift+DOWN", name = "dw-line-down-ctrl-shift", fn = function() cmd_dw_line_move(5, true) end},
        {key = "WHEEL_UP", name = "dw-scroll-up", fn = function() cmd_dw_scroll(-1) end},
        {key = "WHEEL_DOWN", name = "dw-scroll-down", fn = function() cmd_dw_scroll(1) end},
        {key = "Ctrl+UP", name = "dw-scroll-up-ctrl", fn = function() cmd_dw_scroll(-1) end},
        {key = "Ctrl+DOWN", name = "dw-scroll-down-ctrl", fn = function() cmd_dw_scroll(1) end},
        {key = "ESC", name = "dw-close", fn = function() cmd_toggle_drum_window() end},
        {key = "Ctrl+c", name = "dw-copy", fn = function() cmd_dw_copy() end},
        -- Mouse selection
        {key = "MBTN_LEFT", name = "dw-mouse-select", fn = cmd_dw_mouse_handler, complex = true},
        {key = "Shift+MBTN_LEFT", name = "dw-mouse-select-shift", fn = cmd_dw_mouse_shift_handler, complex = true},
        {key = "MBTN_LEFT_DBL", name = "dw-mouse-dblclick", fn = cmd_dw_double_click},
         -- RU Layout
        {key = "ЛЕВЫЙ", name = "dw-word-left-ru", fn = function() cmd_dw_word_move(-1, false) end},
        {key = "ПРАВЫЙ", name = "dw-word-right-ru", fn = function() cmd_dw_word_move(1, false) end},
        {key = "ВВЕРХ", name = "dw-line-up-ru", fn = function() cmd_dw_line_move(-1, false) end},
        {key = "ВНИЗ", name = "dw-line-down-ru", fn = function() cmd_dw_line_move(1, false) end},
        {key = "Shift+ЛЕВЫЙ", name = "dw-word-left-shift-ru", fn = function() cmd_dw_word_move(-1, true) end},
        {key = "Shift+ПРАВЫЙ", name = "dw-word-right-shift-ru", fn = function() cmd_dw_word_move(1, true) end},
        {key = "Shift+ВВЕРХ", name = "dw-line-up-shift-ru", fn = function() cmd_dw_line_move(-1, true) end},
        {key = "Shift+ВНИЗ", name = "dw-line-down-shift-ru", fn = function() cmd_dw_line_move(1, true) end},
        {key = "Ctrl+ВВЕРХ", name = "dw-scroll-up-ctrl-ru", fn = function() cmd_dw_scroll(-1) end},
        {key = "Ctrl+ВНИЗ", name = "dw-scroll-down-ctrl-ru", fn = function() cmd_dw_scroll(1) end},
        {key = "ф", name = "dw-seek-back-ru", fn = function() 
            mp.command("sub-seek -1")
            FSM.DW_FOLLOW_PLAYER = true
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_WORD = 1
        end},
        {key = "в", name = "dw-seek-fwd-ru", fn = function() 
            mp.command("sub-seek 1")
            FSM.DW_FOLLOW_PLAYER = true
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_WORD = 1
        end},
        {key = "ENTER", name = "dw-enter-ru", fn = function() cmd_dw_seek_selected() end},
        {key = "Ctrl+ЛЕВЫЙ", name = "dw-word-left-ctrl-ru", fn = function() cmd_dw_word_move(-5, false) end},
        {key = "Ctrl+ПРАВЫЙ", name = "dw-word-right-ctrl-ru", fn = function() cmd_dw_word_move(5, false) end},
        {key = "Ctrl+Shift+ЛЕВЫЙ", name = "dw-word-left-ctrl-shift-ru", fn = function() cmd_dw_word_move(-5, true) end},
        {key = "Ctrl+Shift+ПРАВЫЙ", name = "dw-word-right-ctrl-shift-ru", fn = function() cmd_dw_word_move(5, true) end},
        {key = "Ctrl+Shift+ВВЕРХ", name = "dw-line-up-ctrl-shift-ru", fn = function() cmd_dw_line_move(-5, true) end},
        {key = "Ctrl+Shift+ВНИЗ", name = "dw-line-down-ctrl-shift-ru", fn = function() cmd_dw_line_move(5, true) end},
        {key = "Ctrl+с", name = "dw-copy-ru", fn = function() cmd_dw_copy() end},
        
        -- Search Toggle
        {key = "Ctrl+f", name = "dw-search-toggle", fn = function() cmd_toggle_search() end},
        {key = "Ctrl+а", name = "dw-search-toggle-ru", fn = function() cmd_toggle_search() end}
    }
    
    for _, k in ipairs(keys) do
        if enable then 
            if k.complex then
                mp.add_forced_key_binding(k.key, k.name, k.fn, {complex = true})
            else
                local settings = nil
                if k.key:match("LEFT") or k.key:match("RIGHT") or k.key:match("UP") or k.key:match("DOWN") 
                   or k.key:match("ЛЕВЫЙ") or k.key:match("ПРАВЫЙ") or k.key:match("ВВЕРХ") or k.key:match("ВНИЗ")
                   or k.key == "a" or k.key == "d" or k.key == "ф" or k.key == "в" 
                   or k.key == "ENTER" or k.key == "KP_ENTER" then
                    settings = "repeatable"
                end
                mp.add_forced_key_binding(k.key, k.name, k.fn, settings)
            end
        else mp.remove_key_binding(k.name) end
    end
    -- Clean up mouse and window state
    if not enable then
        FSM.DW_MOUSE_DRAGGING = false
        mp.remove_key_binding("dw-mouse-drag")
        if FSM.DW_MOUSE_SCROLL_TIMER then
            FSM.DW_MOUSE_SCROLL_TIMER:kill()
            FSM.DW_MOUSE_SCROLL_TIMER = nil
        end
        if FSM.DW_NATIVE_WINDOW_DRAGGING ~= nil then
            mp.set_property_bool("window-dragging", FSM.DW_NATIVE_WINDOW_DRAGGING)
        end
    else
        FSM.DW_NATIVE_WINDOW_DRAGGING = mp.get_property_bool("window-dragging", true)
        mp.set_property_bool("window-dragging", false)
    end
    FSM.DW_KEY_OVERRIDE = enable
end

-- =========================================================================
-- GLOBAL SEARCH FEATURE
-- =========================================================================

local function update_search_results()
    FSM.SEARCH_RESULTS = {}
    FSM.SEARCH_SEL_IDX = 1
    
    if FSM.SEARCH_QUERY == "" then return end
    
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local query_lower = FSM.SEARCH_QUERY:lower()
    
    for i, sub in ipairs(subs) do
        -- Basic substring match
        if sub.text:lower():find(query_lower, 1, true) then
            table.insert(FSM.SEARCH_RESULTS, i)
        end
    end
end

local function draw_search_ui()
    if not FSM.SEARCH_MODE then return "" end
    
    local ass = ""
    local padding_x = 20
    local padding_y = 10
    local font_size = Options.dw_font_size
    local line_height = font_size * 1.2
    
    -- Positioning Constants
    local box_w = 1200
    local box_x = 960 - (box_w / 2)
    local box_y = 50
    
    local bg_color = "181818"
    local border_color = "666666"
    local text_color = "FFFFFF"
    if Options.dw_bg_color then
        bg_color = Options.dw_bg_color
        text_color = Options.dw_text_color
    end
    
    -- Draw Input Field Backing
    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord2}{\\3c&H%s&}{\\1c&H%s&}{\\alpha&H11&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
        box_x, box_y, border_color, bg_color, bg_color, box_w, box_w, line_height + padding_y * 2, line_height + padding_y * 2)
    
    -- Draw Input Text
    local display_query = ""
    local q_table = utf8_to_table(FSM.SEARCH_QUERY)
    
    if #q_table == 0 then
        display_query = "{\\alpha&HAA&}Search...{\\alpha&H00&}|"
    else
        local cur = FSM.SEARCH_CURSOR
        local anc = FSM.SEARCH_ANCHOR
        local has_sel = (anc ~= -1 and anc ~= cur)
        local s_start = has_sel and math.min(anc, cur) or -1
        local s_end = has_sel and math.max(anc, cur) or -1
        
        for i = 1, #q_table do
            if i == s_start + 1 then
                display_query = display_query .. string.format("{\\1c&H%s&}", Options.dw_highlight_color)
            end
            
            if i == cur + 1 and not has_sel then
                display_query = display_query .. "|"
            end
            
            display_query = display_query .. q_table[i]
            
            if i == s_end then
                display_query = display_query .. string.format("{\\1c&H%s&}", text_color)
            end
        end
        
        -- End-of-line cursor or selection start/end
        if cur == #q_table and not has_sel then
            display_query = display_query .. "|"
        end
    end

    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\fs%d}{\\c&H%s&} %s\n",
        box_x + padding_x, box_y + padding_y, font_size, text_color, display_query)
        
    -- Draw Results Dropdown
    if #FSM.SEARCH_RESULTS > 0 then
        local max_results_display = 8
        local display_count = math.min(#FSM.SEARCH_RESULTS, max_results_display)
        local results_h = display_count * line_height + padding_y * 2
        local results_y = box_y + line_height + padding_y * 2 + 5
        
        -- Dropdown Backing
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord2}{\\3c&H%s&}{\\1c&H%s&}{\\alpha&H22&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, border_color, bg_color, bg_color, box_w, box_w, results_h, results_h)
            
        -- Scroll window mapping
        local start_idx = math.max(1, FSM.SEARCH_SEL_IDX - math.floor(max_results_display / 2))
        if start_idx + max_results_display - 1 > #FSM.SEARCH_RESULTS then
            start_idx = math.max(1, #FSM.SEARCH_RESULTS - max_results_display + 1)
        end
        
        for k = 1, display_count do
            local result_idx = start_idx + k - 1
            if result_idx > #FSM.SEARCH_RESULTS then break end
            
            local sub_line_idx = FSM.SEARCH_RESULTS[result_idx]
            local sub_text = Tracks.pri.subs[sub_line_idx].text:gsub("\n", " ")
            
            -- Truncate for display
            if sub_text:len() > 80 then sub_text = sub_text:sub(1, 80) .. "..." end
            
            local item_y = results_y + padding_y + (k - 1) * line_height
            local hl_col = text_color
            if result_idx == FSM.SEARCH_SEL_IDX then hl_col = Options.dw_highlight_color end
            
            ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\fs%d}{\\c&H%s&} %s\n",
                box_x + padding_x, item_y, font_size * 0.8, hl_col, sub_text)
        end
    elseif FSM.SEARCH_QUERY ~= "" then
        -- "No results"
        local results_h = line_height + padding_y * 2
        local results_y = box_y + line_height + padding_y * 2 + 5
        
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord2}{\\3c&H%s&}{\\1c&H%s&}{\\alpha&H22&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, border_color, bg_color, bg_color, box_w, box_w, results_h, results_h)
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\fs%d}{\\c&H%s&} No results found.\n",
            box_x + padding_x, results_y + padding_y, font_size * 0.8, "999999")
    end
    
    return ass
end

local function render_search()
    if not FSM.SEARCH_MODE then
        search_osd.data = ""
        search_osd:update()
        return
    end
    search_osd.data = draw_search_ui()
    search_osd:update()
end

local function move_search_cursor(direction, ctrl, shift)
    local q_table = utf8_to_table(FSM.SEARCH_QUERY)
    if not shift then FSM.SEARCH_ANCHOR = -1 end
    if shift and FSM.SEARCH_ANCHOR == -1 then FSM.SEARCH_ANCHOR = FSM.SEARCH_CURSOR end
    
    local new_pos = FSM.SEARCH_CURSOR
    if ctrl then
        new_pos = get_word_boundary(q_table, new_pos, direction)
    else
        new_pos = math.max(0, math.min(#q_table, new_pos + direction))
    end
    
    FSM.SEARCH_CURSOR = new_pos
    if shift and FSM.SEARCH_ANCHOR == FSM.SEARCH_CURSOR then FSM.SEARCH_ANCHOR = -1 end
    render_search()
end

local function manage_search_bindings(enable)
    if enable then
        FSM.SEARCH_MODE = true
        FSM.SEARCH_QUERY = ""
        FSM.SEARCH_RESULTS = {}
        FSM.SEARCH_SEL_IDX = 1
        FSM.SEARCH_CURSOR = 0
        FSM.SEARCH_ANCHOR = -1
        
        -- Boot subs for memory if haven't already
        if Tracks.pri.path and #Tracks.pri.subs == 0 then
            Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
        end
        
        -- Temporarily clear main DW bindings that conflict with typing if Drum Window is open
        if FSM.DRUM_WINDOW == "DOCKED" then
            manage_dw_bindings(false)
        end
        
        local chars = "abcdefghijklmnopqrstuvwxyz1234567890-=[]\\;',./ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+{}|:\"<>?абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ "
        local function utf8_iter(str)
            return string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*")
        end
        
        for ch in utf8_iter(chars) do
            local key_name = ch
            if ch == " " then key_name = "SPACE" end
            
            mp.add_forced_key_binding(key_name, "search-char-" .. key_name, function()
                local q_table = utf8_to_table(FSM.SEARCH_QUERY)
                
                -- Handle selection delete
                if FSM.SEARCH_ANCHOR ~= -1 and FSM.SEARCH_ANCHOR ~= FSM.SEARCH_CURSOR then
                    local s_start = math.min(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                    local s_end = math.max(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                    for i = s_end, s_start + 1, -1 do
                        table.remove(q_table, i)
                    end
                    FSM.SEARCH_CURSOR = s_start
                    FSM.SEARCH_ANCHOR = -1
                end
                
                table.insert(q_table, FSM.SEARCH_CURSOR + 1, ch)
                FSM.SEARCH_QUERY = table.concat(q_table)
                FSM.SEARCH_CURSOR = FSM.SEARCH_CURSOR + 1
                
                update_search_results()
                render_search()
            end, "repeatable")
        end
        
        -- Special Keys
        mp.add_forced_key_binding("BS", "search-bs", function()
            local q_table = utf8_to_table(FSM.SEARCH_QUERY)
            if FSM.SEARCH_ANCHOR ~= -1 and FSM.SEARCH_ANCHOR ~= FSM.SEARCH_CURSOR then
                local s_start = math.min(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                local s_end = math.max(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                for i = s_end, s_start + 1, -1 do
                    table.remove(q_table, i)
                end
                FSM.SEARCH_QUERY = table.concat(q_table)
                FSM.SEARCH_CURSOR = s_start
                FSM.SEARCH_ANCHOR = -1
                
                update_search_results()
                render_search()
            elseif FSM.SEARCH_CURSOR > 0 then
                table.remove(q_table, FSM.SEARCH_CURSOR)
                FSM.SEARCH_QUERY = table.concat(q_table)
                FSM.SEARCH_CURSOR = FSM.SEARCH_CURSOR - 1
                
                update_search_results()
                render_search()
            end
        end, "repeatable")
        
        mp.add_forced_key_binding("DEL", "search-del", function()
            local q_table = utf8_to_table(FSM.SEARCH_QUERY)
            if FSM.SEARCH_ANCHOR ~= -1 and FSM.SEARCH_ANCHOR ~= FSM.SEARCH_CURSOR then
                local s_start = math.min(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                local s_end = math.max(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                for i = s_end, s_start + 1, -1 do
                    table.remove(q_table, i)
                end
                FSM.SEARCH_QUERY = table.concat(q_table)
                FSM.SEARCH_CURSOR = s_start
                FSM.SEARCH_ANCHOR = -1
                
                update_search_results()
                render_search()
            elseif FSM.SEARCH_CURSOR < #q_table then
                table.remove(q_table, FSM.SEARCH_CURSOR + 1)
                FSM.SEARCH_QUERY = table.concat(q_table)
                
                update_search_results()
                render_search()
            end
        end, "repeatable")
        
        mp.add_forced_key_binding("LEFT", "search-left", function() move_search_cursor(-1, false, false) end, "repeatable")
        mp.add_forced_key_binding("RIGHT", "search-right", function() move_search_cursor(1, false, false) end, "repeatable")
        mp.add_forced_key_binding("Shift+LEFT", "search-left-shift", function() move_search_cursor(-1, false, true) end, "repeatable")
        mp.add_forced_key_binding("Shift+RIGHT", "search-right-shift", function() move_search_cursor(1, false, true) end, "repeatable")
        mp.add_forced_key_binding("Ctrl+LEFT", "search-left-ctrl", function() move_search_cursor(-1, true, false) end, "repeatable")
        mp.add_forced_key_binding("Ctrl+RIGHT", "search-right-ctrl", function() move_search_cursor(1, true, false) end, "repeatable")
        mp.add_forced_key_binding("Ctrl+Shift+LEFT", "search-left-ctrl-shift", function() move_search_cursor(-1, true, true) end, "repeatable")
        mp.add_forced_key_binding("Ctrl+Shift+RIGHT", "search-right-ctrl-shift", function() move_search_cursor(1, true, true) end, "repeatable")

        mp.add_forced_key_binding("HOME", "search-home", function()
            FSM.SEARCH_CURSOR = 0
            FSM.SEARCH_ANCHOR = -1
            render_search()
        end)
        mp.add_forced_key_binding("END", "search-end", function()
            FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
            FSM.SEARCH_ANCHOR = -1
            render_search()
        end)

        mp.add_forced_key_binding("UP", "search-up", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.max(1, FSM.SEARCH_SEL_IDX - 1)
                render_search()
            end
        end, "repeatable")
        
        mp.add_forced_key_binding("DOWN", "search-down", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.min(#FSM.SEARCH_RESULTS, FSM.SEARCH_SEL_IDX + 1)
                render_search()
            end
        end, "repeatable")
        
        mp.add_forced_key_binding("ENTER", "search-enter", function()
            if #FSM.SEARCH_RESULTS > 0 then
                local selected_line = FSM.SEARCH_RESULTS[FSM.SEARCH_SEL_IDX]
                local sub = Tracks.pri.subs[selected_line]
                
                if sub.start_time then
                    mp.commandv("seek", sub.start_time, "absolute+exact")
                end
                
                -- Update DW state so if it opens, or is open, it jumps to this line
                FSM.DW_CURSOR_LINE = selected_line
                FSM.DW_CURSOR_WORD = 1
                FSM.DW_VIEW_CENTER = selected_line
                FSM.DW_FOLLOW_PLAYER = true
                FSM.DW_ANCHOR_LINE = -1
                FSM.DW_ANCHOR_WORD = -1
                
                cmd_toggle_search()
            end
        end)
        
        mp.add_forced_key_binding("ESC", "search-esc", function()
            cmd_toggle_search()
        end)
        
        local function paste_from_clipboard()
            local res = utils.subprocess({ args = {"powershell", "-NoProfile", "-Command", "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Clipboard -Raw"}, cancellable = false })
            if res and res.status == 0 and res.stdout then
                local txt = res.stdout:gsub("\r", ""):gsub("\n", " ")
                if txt ~= "" then
                    local q_table = utf8_to_table(FSM.SEARCH_QUERY)
                    
                    -- Handle selection delete
                    if FSM.SEARCH_ANCHOR ~= -1 and FSM.SEARCH_ANCHOR ~= FSM.SEARCH_CURSOR then
                        local s_start = math.min(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                        local s_end = math.max(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                        for i = s_end, s_start + 1, -1 do
                            table.remove(q_table, i)
                        end
                        FSM.SEARCH_CURSOR = s_start
                        FSM.SEARCH_ANCHOR = -1
                    end

                    local p_table = utf8_to_table(txt)
                    for i = 1, #p_table do
                        table.insert(q_table, FSM.SEARCH_CURSOR + i, p_table[i])
                    end
                    
                    FSM.SEARCH_QUERY = table.concat(q_table)
                    FSM.SEARCH_CURSOR = FSM.SEARCH_CURSOR + #p_table
                    
                    update_search_results()
                    render_search()
                end
            end
        end
        mp.add_forced_key_binding("Ctrl+v", "search-paste", paste_from_clipboard, "repeatable")
        mp.add_forced_key_binding("Ctrl+м", "search-paste-ru", paste_from_clipboard, "repeatable")
        
        local function search_mouse_click(tbl)
            if tbl.event == "down" then
                if #FSM.SEARCH_RESULTS == 0 then return end
                
                local osd_x, osd_y = dw_get_mouse_osd()
                
                -- Check if inside the dropdown Box
                local font_size = Options.dw_font_size
                local line_height = font_size * 1.2
                local padding_y = 10
                local box_w = 1200
                local box_x = 960 - (box_w / 2)
                local box_y = 50
                local results_y = box_y + line_height + padding_y * 2 + 5
                
                local max_results_display = 8
                local display_count = math.min(#FSM.SEARCH_RESULTS, max_results_display)
                local results_h = display_count * line_height + padding_y * 2
                
                if osd_x >= box_x and osd_x <= box_x + box_w then
                    if osd_y >= results_y and osd_y <= results_y + results_h then
                        -- Calculate which item was clicked
                        local rel_y = osd_y - (results_y + padding_y)
                        if rel_y >= 0 and rel_y <= display_count * line_height then
                            local item_idx = math.floor(rel_y / line_height) + 1
                            item_idx = math.max(1, math.min(display_count, item_idx))
                            
                            local start_idx = math.max(1, FSM.SEARCH_SEL_IDX - math.floor(max_results_display / 2))
                            if start_idx + max_results_display - 1 > #FSM.SEARCH_RESULTS then
                                start_idx = math.max(1, #FSM.SEARCH_RESULTS - max_results_display + 1)
                            end
                            
                            local result_idx = start_idx + item_idx - 1
                            if result_idx <= #FSM.SEARCH_RESULTS then
                                FSM.SEARCH_SEL_IDX = result_idx
                                
                                -- Jump immediately as if Enter was pressed
                                local selected_line = FSM.SEARCH_RESULTS[FSM.SEARCH_SEL_IDX]
                                local sub = Tracks.pri.subs[selected_line]
                                
                                if sub.start_time then
                                    mp.commandv("seek", sub.start_time, "absolute+exact")
                                end
                                
                                FSM.DW_CURSOR_LINE = selected_line
                                FSM.DW_CURSOR_WORD = 1
                                FSM.DW_VIEW_CENTER = selected_line
                                FSM.DW_FOLLOW_PLAYER = true
                                FSM.DW_ANCHOR_LINE = -1
                                FSM.DW_ANCHOR_WORD = -1
                                
                                cmd_toggle_search()
                            end
                        end
                    end
                end
            end
        end
        mp.add_forced_key_binding("MBTN_LEFT", "search-mouse-click", search_mouse_click, {complex = true})
        
        render_search()
    else
        FSM.SEARCH_MODE = false
        
        local chars = "abcdefghijklmnopqrstuvwxyz1234567890-=[]\\;',./ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+{}|:\"<>?абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ "
        local function utf8_iter(str)
            return string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*")
        end
        for ch in utf8_iter(chars) do
            local key_name = ch
            if ch == " " then key_name = "SPACE" end
            mp.remove_key_binding("search-char-" .. key_name)
        end
        
        mp.remove_key_binding("search-bs")
        mp.remove_key_binding("search-del")
        mp.remove_key_binding("search-left")
        mp.remove_key_binding("search-right")
        mp.remove_key_binding("search-left-shift")
        mp.remove_key_binding("search-right-shift")
        mp.remove_key_binding("search-left-ctrl")
        mp.remove_key_binding("search-right-ctrl")
        mp.remove_key_binding("search-left-ctrl-shift")
        mp.remove_key_binding("search-right-ctrl-shift")
        mp.remove_key_binding("search-home")
        mp.remove_key_binding("search-end")
        mp.remove_key_binding("search-up")
        mp.remove_key_binding("search-down")
        mp.remove_key_binding("search-enter")
        mp.remove_key_binding("search-esc")
        mp.remove_key_binding("search-paste")
        mp.remove_key_binding("search-paste-ru")
        mp.remove_key_binding("search-mouse-click")
        
        render_search()
        
        if FSM.DRUM_WINDOW == "DOCKED" then
            manage_dw_bindings(true)
        end
    end
end

function cmd_toggle_search()
    if not FSM.SEARCH_MODE then
        if FSM.MEDIA_STATE == "NO_SUBS" then
            show_osd("Search: No subtitles loaded")
            return
        end
        manage_search_bindings(true)
    else
        manage_search_bindings(false)
    end
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
        
        -- Snapshot and hide all subtitle overlays to prevent overlap
        FSM.DW_SAVED_SUB_VIS = mp.get_property_bool("sub-visibility", true)
        FSM.DW_SAVED_SEC_SUB_VIS = mp.get_property_bool("secondary-sub-visibility", true)
        FSM.DW_SAVED_DRUM_STATE = FSM.DRUM  -- "ON" or "OFF"
        mp.set_property_bool("sub-visibility", false)
        mp.set_property_bool("secondary-sub-visibility", false)
        -- If Drum Mode is rendering its own OSD subtitles, hide them too
        if FSM.DRUM == "ON" then
            drum_osd.data = ""
            drum_osd:update()
        end

        local time_pos = mp.get_property_number("time-pos")
        if FSM.DW_CURSOR_LINE == -1 then
            FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, time_pos)
            FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
        end
        FSM.DW_CURSOR_WORD = 1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_FOLLOW_PLAYER = true
        
        if not FSM.SEARCH_MODE then
            manage_dw_bindings(true)
        end
        show_osd("Drum Window: OPEN")
    else
        FSM.DRUM_WINDOW = "OFF"
        if not FSM.SEARCH_MODE then
            manage_dw_bindings(false)
        end
        dw_osd.data = ""
        dw_osd:update()

        -- Restore subtitle visibility to pre-DW state
        if FSM.DW_SAVED_DRUM_STATE == "ON" then
            -- Drum Mode was active: it had already hidden native subs.
            -- Don't touch native sub-visibility (drum manages that).
            -- Drum OSD will resume on the next tick_drum cycle automatically.
        else
            -- Drum Mode was NOT active: restore native sub visibility
            local r_pri = FSM.DW_SAVED_SUB_VIS
            if r_pri == nil then r_pri = true end
            local r_sec = FSM.DW_SAVED_SEC_SUB_VIS
            if r_sec == nil then r_sec = false end
            
            mp.set_property_bool("sub-visibility", r_pri)
            mp.set_property_bool("secondary-sub-visibility", r_sec)
        end

        show_osd("Drum Window: CLOSED")
    end
end

function cmd_dw_scroll(dir)
    FSM.DW_FOLLOW_PLAYER = false
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    FSM.DW_VIEW_CENTER = math.max(1, math.min(#subs, FSM.DW_VIEW_CENTER + dir))
end

local function cmd_dw_seek_selected()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    if FSM.DW_CURSOR_LINE > 0 and FSM.DW_CURSOR_LINE <= #subs then
        local sub = subs[FSM.DW_CURSOR_LINE]
        mp.set_property_number("time-pos", sub.start_time)
        FSM.DW_FOLLOW_PLAYER = true
        show_osd("Seeking to line: " .. FSM.DW_CURSOR_LINE)
    end
end

function cmd_dw_line_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    -- Switch to manual/static mode
    FSM.DW_FOLLOW_PLAYER = false
    
    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = (FSM.DW_CURSOR_WORD > 0) and FSM.DW_CURSOR_WORD or 1
    end
    
    FSM.DW_CURSOR_LINE = math.max(1, math.min(#subs, FSM.DW_CURSOR_LINE + dir))
    
    -- Edge-scroll: if cursor is outside the visible area, snap viewport to show it
    local half = math.floor(Options.dw_lines_visible / 2)
    local view_min = FSM.DW_VIEW_CENTER - half
    local view_max = view_min + Options.dw_lines_visible - 1
    
    if FSM.DW_CURSOR_LINE < view_min then
        -- Cursor is above viewport: snap so cursor is at the top
        FSM.DW_VIEW_CENTER = math.max(1, FSM.DW_CURSOR_LINE + half)
    elseif FSM.DW_CURSOR_LINE > view_max then
        -- Cursor is below viewport: snap so cursor is at the bottom
        FSM.DW_VIEW_CENTER = math.min(#subs, FSM.DW_CURSOR_LINE - half)
    end
    
    if not shift then
        FSM.DW_CURSOR_WORD = 1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    else
        if FSM.DW_CURSOR_WORD == -1 then FSM.DW_CURSOR_WORD = 1 end
    end
end

function cmd_dw_word_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    -- Switch to manual/static mode
    FSM.DW_FOLLOW_PLAYER = false
    
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
mp.add_key_binding(nil, "toggle-drum-search", cmd_toggle_search)
