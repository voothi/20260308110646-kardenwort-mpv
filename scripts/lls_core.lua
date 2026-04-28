local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'

print("[LLS] SCRIPT INITIALIZING: " .. (mp.get_script_directory and mp.get_script_directory() or "<unknown dir>"))

-- =========================================================================
-- LLS CORE CONFIGURATION
-- =========================================================================

-- Forward declarations for interactive logic
local manage_dw_bindings
local update_interactive_bindings

local Options = {
    -- AutoPause
    autopause_default = true,
    karaoke_every_word = false,
    pause_padding = 0.15,
    karaoke_token = "{\\c}",
    space_tap_delay = 0.2,

    -- Drum Mode
    drum_font_size = 34,
    drum_font_name = "Consolas",
    drum_font_bold = false,
    drum_context_lines = 3,
    drum_context_opacity = "30",
    drum_context_color = "CCCCCC",
    drum_context_bold = false,
    drum_context_size_mul = 1.0,
    drum_active_opacity = "00",
    drum_active_color = "FFFFFF",
    drum_active_bold = false,
    drum_active_size_mul = 1.0,
    drum_line_height_mul = 0.87,
    drum_bg_color = "000000",       -- black in BGR hex for ASS
    drum_bg_opacity = "60",         -- background opacity (00-FF, 00 is opaque)
    drum_border_size = 1.5,
    drum_shadow_offset = 1.0,
    drum_double_gap = true,
    drum_vsp = 0,
    drum_block_gap_mul = -0.27,
    drum_gap_adj = 6,
    drum_track_gap = 5.0,         -- Extra spacing between dual tracks (%)
    osd_interactivity = true,     -- Enable mouse interaction for main subtitles

    -- SRT Style (Regular Mode)
    srt_font_size = 34,
    srt_font_name = "Consolas",
    srt_font_bold = false,
    srt_active_color = "FFFFFF",   -- Active playback line color
    srt_context_color = "CCCCCC",  -- Surrounding lines color
    srt_active_opacity = "00",     -- Transparency for active line
    srt_context_opacity = "30",    -- Transparency for context lines
    srt_bg_color = "000000",       -- Shadow/Frame color
    srt_bg_opacity = "60",         -- Shadow/Frame transparency
    srt_border_size = 1.5,
    srt_shadow_offset = 1.0,
    srt_double_gap = true,
    srt_vsp = 0,
    srt_block_gap_mul = -0.27,
    srt_line_height_mul = 0.87,     -- Vertical spacing multiplier

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
    osd_duration = 0.5,

    -- Drum Window
    dw_font_size = 34,
    dw_lines_visible = 15,        -- how many lines visible in the window
    dw_scrolloff = 3,             -- margin lines at top/bottom before scrolling
    dw_bg_color = "000000",       -- black in BGR hex for ASS
    dw_bg_opacity = "60",         -- background opacity (00-FF, 00 is opaque)
    dw_context_color = "CCCCCC",  -- light text
    dw_active_color = "FFFFFF",   -- white active text in BGR
    dw_active_bold = false,
    dw_context_bold = false,
    dw_active_opacity = "00",     -- text alpha for active playback line
    dw_context_opacity = "30",    -- text alpha for context lines
    dw_active_size_mul = 1.0,
    dw_context_size_mul = 1.0,
    dw_highlight_color = "00CCFF",-- Gold highlight in BGR
    dw_ctrl_select_color = "FF88FF",-- Neon pink for split-word select (pairing with purple)
    dw_font_name = "Consolas",    -- monospace font for perfect hit-testing
    dw_char_width = 0.5,          -- char width multiplier (0.5 is exact for Consolas)
    dw_line_height_mul = 0.87,    -- visual line height = dw_font_size * this (calibrated for font 34, use 0.9 for font 30)
    dw_block_gap_mul = -0.27,      -- gap between subtitles = dw_font_size * this (calibrated for font 34, use 0.6 for font 30)
    dw_double_gap = true,         -- Use double newline (\N\N) between subtitles
    dw_vsp = 0,                   -- Vertical spacing adjustment (pixels)
    dw_border_size = 1.5,
    dw_shadow_offset = 1.0,
    dw_original_spacing = true,
    dw_jump_words = 5,            -- Words to jump on Ctrl+Left/Right
    dw_jump_lines = 5,            -- Lines to jump on Ctrl+Shift+Up/Down

    -- Search HUD Styling
    search_font_name = "Consolas",
    search_font_size = 34,
    search_results_font_size = 0,    -- 0 = 100%, -1 = 80%, >0 = fixed size
    search_bg_color = "000000",      -- black in BGR hex for ASS
    search_bg_opacity = "20",        -- background opacity (00-FF, 00 is opaque)
    search_text_color = "FFFFFF",
    search_border_size = 2.0,
    search_shadow_offset = 1.0,
    search_line_height_mul = 1.2,
    search_hit_color = "0088FF",       -- Match highlighting (BGR)
    search_hit_bold = false,            -- Bold matches?
    search_sel_color = "FFFFFF",       -- Selected line color (White)
    search_sel_bold = false,           -- Bold selected line?
    search_query_hit_color = "0088FF", -- Search bar text hits (Select All/Selection)
    search_query_hit_bold = false,      -- Bold search bar hits?

    -- Font Scaling (Ported from fixed_font.lua)
    font_scaling_enabled = true,
    font_base_height = 1080,
    font_base_scale = 1.0,
    font_scale_strength = 0.5,

    -- Tooltip Style (Unified Schema)
    tooltip_font_size = 34,
    tooltip_font_name = "Consolas",
    tooltip_font_bold = false,
    tooltip_context_lines = 3,
    tooltip_active_color = "FFFFFF",   -- Active translation line color
    tooltip_context_color = "CCCCCC",  -- Surrounding lines color
    tooltip_active_opacity = "00",     -- Transparency for active line
    tooltip_context_opacity = "30",    -- Transparency for context lines
    tooltip_bg_color = "222222",       -- Background color (BGR hex)
    tooltip_bg_opacity = "60",         -- Background transparency
    tooltip_border_size = 1.5,
    tooltip_shadow_offset = 1.0,
    tooltip_line_height_mul = 0.87,     -- Vertical spacing multiplier
    tooltip_block_gap_mul = -0.27,
    tooltip_double_gap = true,         -- Use double newline (\N\N) between context lines
    tooltip_vsp = 0,                   -- Vertical spacing adjustment (pixels)
    tooltip_y_offset_lines = 0,        -- Vertical shift in number of lines (positive = down, negative = up)

    -- Navigation Repeat
    seek_hold_delay = 0.5,
    seek_hold_rate = 10,

    -- Anki Highlighter
    dw_key_add = "g п MBTN_MID Ctrl+MBTN_MID",
    dw_key_pair = "f а Ctrl+MBTN_LEFT",
    dw_key_select = "MBTN_LEFT",
    dw_key_pair_mod = "Ctrl",
    dw_key_tooltip_pin = "MBTN_RIGHT",
    dw_key_tooltip_hover = "n т",
    dw_key_tooltip_toggle = "e у",
    dw_key_seek_prev = "a ф",
    dw_key_seek_next = "d в",
    dw_key_search = "Ctrl+f Ctrl+а",
    dw_key_copy = "Ctrl+c Ctrl+с",
    dw_key_seek = "ENTER KP_ENTER",
    dw_key_esc = "ESC",
    dw_key_select_extend = "Shift+MBTN_LEFT",
    dw_key_mouse_seek = "MBTN_LEFT_DBL",
    dw_key_jump_left = "Ctrl+LEFT Ctrl+ЛЕВЫЙ",
    dw_key_jump_right = "Ctrl+RIGHT Ctrl+ПРАВЫЙ",
    dw_key_jump_select_left = "Ctrl+Shift+LEFT Ctrl+Shift+ЛЕВЫЙ",
    dw_key_jump_select_right = "Ctrl+Shift+RIGHT Ctrl+Shift+ПРАВЫЙ",
    dw_key_scroll_up = "Ctrl+UP Ctrl+ВВЕРХ",
    dw_key_scroll_down = "Ctrl+DOWN Ctrl+ВНИЗ",
    dw_key_jump_select_up = "Ctrl+Shift+UP Ctrl+Shift+ВВЕРХ",
    dw_key_jump_select_down = "Ctrl+Shift+DOWN Ctrl+Shift+ВНИЗ",
    dw_key_select_left = "Shift+LEFT Shift+ЛЕВЫЙ",
    dw_key_select_right = "Shift+RIGHT Shift+ПРАВЫЙ",
    dw_key_select_up = "Shift+UP Shift+ВВЕРХ",
    dw_key_select_down = "Shift+DOWN Shift+ВНИЗ",
    dw_key_cycle_copy_mode = "z я",
    dw_key_toggle_copy_context = "x ч",
    -- Search Mode (Drum Window)
    search_key_bs = "BS",
    search_key_del = "DEL",
    search_key_select_left = "Shift+LEFT",
    search_key_select_right = "Shift+RIGHT",
    search_key_jump_left = "Ctrl+LEFT",
    search_key_jump_right = "Ctrl+RIGHT",
    search_key_home = "HOME",
    search_key_end = "END",
    search_key_enter = "ENTER",
    search_key_esc = "ESC",
    search_key_paste = "Ctrl+v Ctrl+м",
    search_key_select_all = "Ctrl+a Ctrl+ф",
    search_key_delete_word = "Ctrl+w Ctrl+ц",
    search_key_click = "MBTN_LEFT",
    dw_key_open_record = "o щ",
    key_sub_pos_up = "r к",
    key_sub_pos_down = "t е",
    key_sec_sub_pos_up = "R К",
    key_sec_sub_pos_down = "T Е",
    anki_context_max_words = 40,
    anki_context_span_pad = 3,        -- Extra words added before/after a wide paired selection
    anki_highlight_depth_1 = "0075D1",
    anki_highlight_depth_2 = "005DAE",
    anki_highlight_depth_3 = "003C88",
    anki_split_depth_1 = "FF88B0",
    anki_split_depth_2 = "D97496",
    anki_split_depth_3 = "B3607C",
    anki_mix_depth_1 = "4A4AD3",
    anki_mix_depth_2 = "3636A8",
    anki_mix_depth_3 = "151578",
    anki_global_highlight = false,
    anki_sync_period = 5,
    anki_context_lines = 6,
    anki_local_fuzzy_window = 10.0,
    anki_split_search_window = 35,      -- Line search window for paired words (+/- segments)
    anki_split_gap_limit = 60.0,        -- Max temporal gap between paired words (seconds)
    anki_neighbor_window = 5,           -- Context window for neighbor identification (+/- segments)
    anki_context_strict = false,
    anki_highlight_bold = false,
    anki_strip_metadata = true,
    anki_abbrev_list = "ca. z.B. usw. bzw. etc. t.con",
    anki_abbrev_smart = true,
    book_mode = false,

    -- Record File
    record_editor = "C:\\Program Files\\Microsoft VS Code\\Code.exe",
    
    -- Colors
    dw_split_select_color = "FF88B0",
    dw_mouse_shield_ms = 50,       -- Ghost-click suppression window after keyboard commands (ms)
    sentence_word_threshold = 3
}
options.read_options(Options, "lls")

-- =========================================================================
-- CORE UTILITIES (Moved up for visibility)
-- =========================================================================

function show_osd(msg, dur)
    local style = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(style .. "{\\an4}{\\fs20}" .. msg, dur or Options.osd_duration)
end

function has_cyrillic(str)
    if not str then return false end
    return str:match("[\208-\209][\128-\191]") ~= nil
end

function get_center_index(subs, time_pos)
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
    
    if best == -1 then return 1 end
    
    if time_pos <= subs[best].end_time then
        return best
    end
    
    if best < #subs then
        local next_sub = subs[best + 1]
        if (time_pos - subs[best].end_time) < (next_sub.start_time - time_pos) then
            return best
        else
            return best + 1
        end
    end
    
    return best
end

function parse_time(time_str)
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

function clean_text_srt(line)
    if not line then return "" end
    line = line:gsub("^\xEF\xBB\xBF", "")
    return line:gsub("\r", ""):gsub("<[^>]+>", ""):gsub("%z", "")
end

function load_sub(path, is_ass)
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
                            raw_text = raw_text:gsub("%s+", " "):gsub("%z", ""):match("^%s*(.-)%s*$")
                            if raw_text ~= "" then
                                local parsed_start = parse_time(start_str)
                                local parsed_end = parse_time(end_str)
                                local merged = false
                                local prev = subs[#subs]
                                if prev and prev.raw_text == raw_text then
                                    -- Only merge if consecutive and close (gap <= 200ms)
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
        for raw_line in f:lines() do
            local line = clean_text_srt(raw_line)
            if line == "" then
                if current_sub and current_sub.text ~= "" then
                    current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
                    local merged = false
                    local prev = subs[#subs]
                    if prev and prev.raw_text == current_sub.raw_text then
                        -- Only merge if consecutive and close (gap <= 200ms)
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
            local merged = false
            local prev = subs[#subs]
            if prev and prev.raw_text == current_sub.raw_text then
                -- Only merge if consecutive and close (gap <= 200ms)
                if current_sub.start_time <= prev.end_time + 0.2 then
                    prev.end_time = math.max(prev.end_time, current_sub.end_time)
                    merged = true
                end
            end
            if not merged then
                table.insert(subs, current_sub)
            end
        end
    end
    f:close()
    table.sort(subs, function(a, b) return a.start_time < b.start_time end)
    return subs
end

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
    BOOK_MODE = Options.book_mode or false,
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
    DW_CURSOR_X = nil,         -- Sticky horizontal position for up/down nav (OSD x, nil = use line midpoint)
    DW_ANCHOR_LINE = -1,       -- Shift-anchor line index
    DW_ANCHOR_WORD = -1,       -- Shift-anchor word index
    DW_VIEW_CENTER = -1,       -- Viewport center line index
    DW_FOLLOW_PLAYER = true,   -- Follow active playback line?
    DW_KEY_OVERRIDE = false,   -- Are we overriding arrow keys?
    DW_MOUSE_DRAGGING = false, -- True while LMB is held and dragging
    DW_CTRL_HELD = false,      -- True while Ctrl key is held in DW
    DW_CTRL_PENDING_SET = {},  -- Non-contiguous word selection {{line, word}, ...}
    DW_MOUSE_SCROLL_TIMER = nil, -- Timer for auto-scroll while dragging at edges

    -- Performance Caches
    DW_LAYOUT_CACHE = nil,     -- Cached layout for the current viewport
    -- Global Search State
    SEARCH_MODE = false,
    SEARCH_QUERY = "",
    SEARCH_RESULTS = {},
    SEARCH_SEL_IDX = 1,
    SEARCH_CURSOR = 0,
    SEARCH_ANCHOR = -1,

    -- Transient UI State
    saved_osd_border_style = nil,
    DRUM_HIT_ZONES = nil,      -- Hit-zone metadata for active Drum/SRT OSD

    -- Tooltip State
    DW_TOOLTIP_LINE = -1,
    DW_TOOLTIP_MODE = "CLICK",
    DW_TOOLTIP_HOLDING = false,
    DW_TOOLTIP_LOCKED_LINE = -1,
    DW_TOOLTIP_FORCE = false,   -- Manual keyboard toggle state
    DW_LINE_Y_MAP = {},         -- Map of {sub_idx = osd_y} for active tooltip tracking
    DW_ACTIVE_LINE = -1,        -- Currently playing subtitle index
    DW_TOOLTIP_TARGET_MODE = "ACTIVE", -- Target switching for forced tooltip ("ACTIVE" or "CURSOR")
    DW_SEEKING_MANUALLY = false,
    DW_SEEK_TARGET = -1,
    DW_MOUSE_LOCK_UNTIL = 0,         -- Timestamp to ignore mouse events (shielding)

    -- Repeat Timer
    SEEK_REPEAT_TIMER = nil,

    -- Anki Highlighter State
    ANKI_HIGHLIGHTS = {},
    ANKI_DB_PATH = nil,
    ANKI_DB_MTIME = 0,
    ANKI_DB_SIZE = 0
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

local dw_tooltip_osd = mp.create_osd_overlay("ass-events")
dw_tooltip_osd.res_x = 1920
dw_tooltip_osd.res_y = 1080
dw_tooltip_osd.z = 25

local dw_ensure_visible -- forward declaration

-- =========================================================================
-- COPY CONTEXT LOGIC (Moved up for visibility)
-- =========================================================================

function cmd_cycle_copy_mode()
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Copy Mode: No subtitles loaded")
        return
    end
    if FSM.MEDIA_STATE == "SINGLE_SRT" then
        show_osd("Copy Mode: Fixed to Primary (Single Track)")
        return
    end
    FSM.COPY_MODE = (FSM.COPY_MODE == "A") and "B" or "A"
    
    local label = (FSM.COPY_MODE == "A") and "A (Primary/Target)" or "B (Secondary/Translation)"
    show_osd("Copy Subtitle Mode: " .. label)
end

function cmd_toggle_copy_ctx()
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

function get_copy_context_text(time_pos, line_idx)
    time_pos = time_pos or mp.get_property_number("time-pos") or 0
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
    
    local function append(path, is_ass, explicit_idx)
        if not path then return end
        local subs = nil
        if Tracks.pri.path == path and FSM.DRUM == "ON" and not is_ass then subs = Tracks.pri.subs
        elseif Tracks.sec.path == path and FSM.DRUM == "ON" and not is_ass then subs = Tracks.sec.subs
        else subs = load_sub(path, is_ass) end

        if subs and #subs > 0 then
            local idx = explicit_idx or get_center_index(subs, time_pos)
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
    
    append(Tracks.pri.path, Tracks.pri.is_ass, line_idx)
    if Tracks.sec.path and Tracks.sec.path ~= Tracks.pri.path then
        append(Tracks.sec.path, Tracks.sec.is_ass)
    end
    
    return #combined > 0 and table.concat(combined, "\n") or nil
end


local ANKI_MAPPING_CACHE = nil

local function load_anki_mapping_ini()
    if ANKI_MAPPING_CACHE then return ANKI_MAPPING_CACHE end
    
    local path = mp.command_native({"expand-path", "~~/script-opts/anki_mapping.ini"})
    local f = io.open(path, "r")
    local config = {
        fields = {},
        mapping = {},
        mapping_word = {},
        mapping_sentence = {},
        tts = {},
        settings = {}
    }
    
    if not f then 
        ANKI_MAPPING_CACHE = config
        return config 
    end

    local section = nil

    for line in f:lines() do
        local clean_line = line:match("^%s*(.-)%s*$")
        if clean_line ~= "" and not clean_line:match("^#") and not clean_line:match("^;") then
            local header = clean_line:match("^%[(.+)%]$")
            if header then
                section = header:lower()
            elseif section == "fields" then
                table.insert(config.fields, clean_line)
            elseif section == "fields.word" then
                table.insert(config.fields_word, clean_line)
            elseif section == "fields.sentence" then
                table.insert(config.fields_sentence, clean_line)
            elseif section == "fields_mapping.word" then
                local k, v = clean_line:match("^([^=]+)=(.*)$")
                if k and v then
                    k = k:match("^%s*(.-)%s*$")
                    v = v:match("^%s*(.-)%s*$")
                    if (v:match('^".*"$') or v:match("^'.*'$")) then v = v:sub(2, -2) end
                    config.mapping_word[k] = v
                end
            elseif section == "fields_mapping.sentence" then
                local k, v = clean_line:match("^([^=]+)=(.*)$")
                if k and v then
                    k = k:match("^%s*(.-)%s*$")
                    v = v:match("^%s*(.-)%s*$")
                    if (v:match('^".*"$') or v:match("^'.*'$")) then v = v:sub(2, -2) end
                    config.mapping_sentence[k] = v
                end
            elseif section == "mapping" or section == "tts" or section == "settings" then
                local k, v = clean_line:match("^([^=]+)=(.*)$")
                if k and v then
                    k = k:match("^%s*(.-)%s*$")
                    v = v:match("^%s*(.-)%s*$")
                    if (v:match('^".*"$') or v:match("^'.*'$")) then
                        v = v:sub(2, -2)
                    end
                    config[section][k] = v
                end
            end
        elseif clean_line == "" then
            if section == "fields" then
                table.insert(config.fields, "") -- hole
            elseif section == "fields.word" then
                table.insert(config.fields_word, "")
            elseif section == "fields.sentence" then
                table.insert(config.fields_sentence, "")
            end
        end
    end
    f:close()

    
    ANKI_MAPPING_CACHE = config
    return config
end

local function extract_subtitle_metadata(path)
    if not path or path == "" then return "", "" end
    local filename = path:match("([^/\\]+)$") or path
    local base = filename:gsub("%.[^.]+$", "")
    local lang_code = base:match("%.([a-zA-Z%-]+)$")
    if lang_code then
        return base, lang_code:lower()
    end
    return base, ""
end

local SOURCE_URL_CACHE = nil
local SOURCE_URL_FILE_PATH = nil
local SOURCE_URL_FILE_MTIME = 0
local SOURCE_URL_FILE_SIZE = 0
local LAST_PATH_FOR_URL = nil

local function find_source_url()
    local path = mp.get_property("path")
    if not path or path == "" then return "" end
    
    -- Cache validation: if we have a file path, check if it changed
    if path == LAST_PATH_FOR_URL and SOURCE_URL_FILE_PATH then
        local info = utils.file_info(SOURCE_URL_FILE_PATH)
        if info then
            if info.mtime == SOURCE_URL_FILE_MTIME and info.size == SOURCE_URL_FILE_SIZE and SOURCE_URL_CACHE and SOURCE_URL_CACHE ~= "" then
                -- File unchanged and we have a valid URL cached, skip scan
                return SOURCE_URL_CACHE
            end
            -- File exists but changed, proceed to re-parse (Step 1 below will handle it)
        else
            -- File was deleted or renamed, invalidate cache
            SOURCE_URL_CACHE = nil
            SOURCE_URL_FILE_PATH = nil
            SOURCE_URL_FILE_MTIME = 0
            SOURCE_URL_FILE_SIZE = 0
        end
    elseif path == LAST_PATH_FOR_URL and SOURCE_URL_CACHE ~= nil and SOURCE_URL_CACHE ~= "" then 
        -- We have a cached URL but no path (e.g. was found by directory scan loop but not recorded path?)
        -- Actually SOURCE_URL_FILE_PATH should always be set if found.
        return SOURCE_URL_CACHE 
    end

    LAST_PATH_FOR_URL = path
    SOURCE_URL_CACHE = "" -- Default fallback
    SOURCE_URL_FILE_PATH = nil

    local dir, filename = utils.split_path(path)
    if not dir or dir == "" then return "" end
    
    local base_name = filename:gsub("%.[^.]+$", "")

    local function parse_url_file(target_path)
        local f = io.open(target_path, "r")
        if not f then return nil end
        for line in f:lines() do
            local clean = line:gsub("^\xEF\xBB\xBF", ""):match("^%s*(.-)%s*$")
            local url = clean:match("^[Uu][Rr][Ll]%s*=%s*(https?://%S+)")
            if url then
                f:close()
                return url, target_path
            end
        end
        f:close()
        return nil
    end

    -- 1. Try specific filename matches (base_name.url, base_name.txt, etc)
    local extensions = { ".url", ".txt", ".md" }
    for _, ext in ipairs(extensions) do
        local url, f_path = parse_url_file(utils.join_path(dir, base_name .. ext))
        if url then
            SOURCE_URL_CACHE = url
            SOURCE_URL_FILE_PATH = f_path
            local info = utils.file_info(f_path)
            if info then
                SOURCE_URL_FILE_MTIME = info.mtime
                SOURCE_URL_FILE_SIZE = info.size
            end
            return url
        end
    end

    -- 2. Fallback: Search for any .url file in the directory
    local files = utils.readdir(dir, "files")
    if files then
        for _, f_name in ipairs(files) do
            if f_name:lower():match("%.url$") then
                local url, f_path = parse_url_file(utils.join_path(dir, f_name))
                if url then
                    SOURCE_URL_CACHE = url
                    SOURCE_URL_FILE_PATH = f_path
                    return url
                end
            end
        end
    end

    return SOURCE_URL_CACHE
end

local function escape_tsv(str)
    if type(str) ~= "string" then return tostring(str or "") end
    return (str:gsub("\t", " "):gsub("\n", " "))
end

local function resolve_anki_field(field_name, term, context, time_pos, deck_name, pri_lang, sec_lang, mapping, tts, item_index)
    if not field_name or field_name == "" then return "" end
    
    local source = mapping[field_name]
    if not source then
        source = tts[field_name]
        if not source then return "" end
    end
    
    if source == "source_word" then return escape_tsv(term) end
    if source == "source_sentence" then return escape_tsv(context) end
    if source == "source_index" then return tostring(item_index or "") end
    if source == "source_url" then return escape_tsv(find_source_url()) end
    if source == "time" then return string.format("%.3f", time_pos) end
    if source == "deck_name" then return escape_tsv(deck_name) end

    
    if source:match("^tts_source_") then
        local tts_lang = source:match("^tts_source_(.+)$")
        if tts_lang and pri_lang and tts_lang:lower() == pri_lang:lower() then return "1" end
        return ""
    end
    if source:match("^tts_dest_") then
        local tts_lang = source:match("^tts_dest_(.+)$")
        -- Destination flags check the secondary track's language
        if tts_lang and sec_lang and tts_lang:lower() == sec_lang:lower() then return "1" end
        
        -- Fallback: If no secondary language is detected, default to Russian ("ru")
        if (not sec_lang or sec_lang == "") and tts_lang == "ru" then
            return "1"
        end
        return ""
    end
    
    if source == "1" then return "1" end
    return escape_tsv(source)
end

local function calculate_ass_alpha(val)
    if type(val) == "string" and #val == 2 and val:match("%x%x") then
        return val:upper()
    end
    local num = tonumber(val)
    if not num then return "00" end
    -- If value is 0-1 (decimal opacity), convert to transparency percentage
    if num >= 0 and num <= 1 then
        num = (1.0 - num) * 100
    end
    -- Clamp to 0-100
    num = math.max(0, math.min(100, num))
    -- Convert 0-100 transparency to 00-FF hex
    local hex = string.format("%02X", math.floor((num / 100) * 255 + 0.5))
    return hex
end





local function utf8_to_table(str)
    local t = {}
    for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(t, ch)
    end
    return t
end

local function utf8_to_lower(str)
    local res = str:lower()
    local upper = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ"
    local lower = "абвгдеёжзийклмнопрстуфхцчшщъыьэюяäöüß"
    local u_table = utf8_to_table(upper)
    local l_table = utf8_to_table(lower)
    for i = 1, #u_table do
        res = res:gsub(u_table[i], l_table[i])
    end
    return res
end

local function has_cyrillic(str)
    if not str then return false end
    return str:find("[\208\209]") ~= nil
end

local function is_word_char(c)
    if not c or #c == 0 then return false end
    -- ASCII alphanumeric + apostrophe
    if c:match("^[%w']$") then return true end
    -- German/Russian/Cyrillic support
    local u = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ"
    local l = "абвгдеёжзийклмнопрстуфхцчшщъыьэюяäöüß"
    if u:find(c, 1, true) or l:find(c, 1, true) then return true end
    return false
end



local function build_word_list_internal(text, keep_spaces)
    local tokens = {}
    if not text then return tokens end
    
    local chars = utf8_to_table(text)
    local i = 1
    local n = #chars
    local curr_logical_idx = 1
    local curr_sub_idx = 0.1
    local curr_visual_idx = 1
    
    while i <= n do
        local c = chars[i]
        local token = { text = "", is_word = false, logical_idx = nil, visual_idx = curr_visual_idx }
        
        -- 1. Handle ASS Tags (Atomize)
        if c == "{" then
            local start = i
            while i <= n and chars[i] ~= "}" do i = i + 1 end
            token.text = table.concat(chars, "", start, math.min(i, n))
            i = i + 1
            
        -- 2. Handle Metadata Brackets
        elseif c == "[" then
            local start = i
            while i <= n and chars[i] ~= "]" do i = i + 1 end
            token.text = table.concat(chars, "", start, math.min(i, n))
            token.is_word = true
            token.logical_idx = curr_logical_idx
            curr_logical_idx = curr_logical_idx + 1
            curr_sub_idx = 0.1
            i = i + 1
            
        -- 3. Handle Whitespace
        elseif c:match("^%s$") or c == "\194\160" then
            local start = i
            while i <= n and (chars[i]:match("^%s$") or chars[i] == "\194\160") do i = i + 1 end
            if keep_spaces then
                token.text = table.concat(chars, "", start, i - 1)
                token.logical_idx = (curr_logical_idx - 1) + curr_sub_idx
                curr_sub_idx = curr_sub_idx + 0.1
            else
                token = nil
            end
            
        -- 4. Handle Word Characters (Scanning contiguous blocks)
        elseif is_word_char(c) then
            local start = i
            while i <= n and is_word_char(chars[i]) do i = i + 1 end
            token.text = table.concat(chars, "", start, i - 1)
            token.is_word = true
            token.logical_idx = curr_logical_idx
            curr_logical_idx = curr_logical_idx + 1
            curr_sub_idx = 0.1
            
        -- 5. Handle Punctuation/Misc (Atomic Separator)
        else
            token.text = c
            token.logical_idx = (curr_logical_idx - 1) + curr_sub_idx
            curr_sub_idx = curr_sub_idx + 0.1
            i = i + 1
        end

        if token then
            table.insert(tokens, token)
            curr_visual_idx = curr_visual_idx + 1
        end
    end
    return tokens
end

local function build_word_list(text)
    local tokens = build_word_list_internal(text, false)
    local words = {}
    for _, t in ipairs(tokens) do
        if t.is_word then
            table.insert(words, t.text)
        end
    end
    return words
end

local function get_sub_tokens(s)
    if not s then return nil end
    if not s.tokens then 
        local raw_text = s.text:gsub("\n", " ")
        s.tokens = build_word_list_internal(raw_text, Options.dw_original_spacing)
        local wc = 0
        for _, t in ipairs(s.tokens) do if t.is_word then wc = wc + 1 end end
        s.word_count = wc
    end
    return s.tokens
end


local function is_word_token(t)
    if not t then return false end
    if type(t) == "table" then return t.is_word == true end
    -- Fallback for string tokens (if any)
    if #t == 0 then return false end
    return not t:match("^%s+$")
end

local function compose_term_smart(words)
    if not words or #words == 0 then return "" end
    local res = ""
    for idx, w in ipairs(words) do
        res = res .. w
        local next_w = words[idx + 1]
        
        if next_w then
            -- Smart joiner: No space based on punctuation rules (covers English, German, Russian, etc.)
            local no_space_before = next_w:match("[%.,!?;:…»”%)%]%}]$") 
                                  or next_w:match("^[/-]$") 
                                  or next_w:match("^\226\128\147$") -- en-dash
                                  or next_w:match("^\226\128\148$") -- em-dash
                                  or next_w:match("^[\"']$")
            
            local no_space_after = w:match("^[/-]$") 
                                 or w:match("^\226\128\147$") 
                                 or w:match("^\226\128\148$") 
                                 or w:match("^[%[%({¿¡«„“]$")
                                 or w:match("^[\"']$")
            
            if no_space_before or no_space_after then
                -- Join without space
            else
                res = res .. " "
            end
        end
    end
    return res
end


local function find_fuzzy_indices(str_lower, query_lower)
    if query_lower == "" then return {} end
    local str_t = utf8_to_table(str_lower)
    local query_t = utf8_to_table(query_lower)
    
    local indices = {}
    local j = 1
    
    for i = 1, #str_t do
        if str_t[i] == query_t[j] then
            table.insert(indices, i)
            if j == #query_t then 
                return indices
            end
            j = j + 1
        end
    end
    return nil
end

local function calculate_match_score(str, query)
    if query == "" then return 0 end
    local str_lower = utf8_to_lower(str)
    local query_lower = utf8_to_lower(query)
    
    -- Exact match is highest priority
    if str_lower == query_lower then return 2000 end

    -- Tokenize query by spaces
    local tokens = {}
    for token in query_lower:gmatch("%S+") do
        table.insert(tokens, token)
    end
    if #tokens == 0 then return 0 end

    -- Check if ALL tokens are present as FUZZY SUBSEQUENCES in the string
    local matches = {}
    for i, token in ipairs(tokens) do
        -- Check for literal substring first (higher signal)
        local start_pos, end_pos = str_lower:find(token, 1, true)
        if start_pos then
            -- Convert character positions to indices for highlighting
            -- (Literal matches are contiguous, so we generate the indices)
            local indices = {}
            local s_table = utf8_to_table(str_lower)
            -- Note: find returns byte positions. We need to find the character-index equivalent.
            -- However, utf8_to_lower might change byte length but not character count for cyrillic.
            -- Actually, simpler to just use find_fuzzy_indices on the token since it's a literal match
            local n_indices = find_fuzzy_indices(str_lower, token)
            -- But find_fuzzy_indices might skip characters if not contiguous? 
            -- No, literal search is better. Let's find the start character index.
            local char_start = 0
            local cur_byte = 1
            while cur_byte < start_pos do
                local b = str_lower:byte(cur_byte)
                if b < 128 then cur_byte = cur_byte + 1
                elseif b < 224 then cur_byte = cur_byte + 2
                elseif b < 240 then cur_byte = cur_byte + 3
                else cur_byte = cur_byte + 4 end
                char_start = char_start + 1
            end
            
            local token_char_len = #utf8_to_table(token)
            for k = 1, token_char_len do
                table.insert(indices, char_start + k)
            end
            
            table.insert(matches, {indices = indices, literal = true, span = token_char_len})
        else
            -- Fallback to fuzzy subsequence for this specific word/token
            local indices = find_fuzzy_indices(str_lower, token)
            if not indices then
                return 0 -- Every keyword must match at least fuzzily
            end
            local span = indices[#indices] - indices[1] + 1
            table.insert(matches, {indices = indices, literal = false, span = span})
        end
    end

    -- Base score for finding all keywords
    local score = 500

    -- Bonus: Compactness & Literal Signal
    for i, m in ipairs(matches) do
        if m.literal then 
            score = score + 200 
        else
            -- Fuzzy match compactness bonus
            -- If span is short (e.g. <= token length + 2), it's likely within a word or two
            local token_len = #utf8_to_table(tokens[i])
            if m.span <= token_len + 1 then
                score = score + 150 -- Very compact
            elseif m.span <= token_len + 5 then
                score = score + 5 -- Reasonably compact
            end
        end
    end

    -- Bonus: All words in correct sequential order
    local last_pos = 0
    local in_order = true
    for _, m in ipairs(matches) do
        if m.indices[1] < last_pos then
            in_order = false
            break
        end
        last_pos = m.indices[#m.indices]
    end
    if in_order and #matches > 0 then
        score = score + 300
    end

    -- Bonus: Start of sentence match
    if matches[1].indices[1] == 1 then
        score = score + 300
    end

    -- Bonus: Contiguous whole query string match
    if str_lower:find(query_lower, 1, true) then
        score = score + 400
    end

    -- Aggregate all indices for highlighting
    local all_indices = {}
    for _, m in ipairs(matches) do
        for _, idx in ipairs(m.indices) do
            all_indices[idx] = true
        end
    end

    return score, all_indices
end

local function is_word_char(ch)
    if not ch then return false end
    return ch:match("[%w\128-\255]") ~= nil
end

local L_EPSILON = 0.0001

local function logical_cmp(a, b)
    if not a or not b then return false end
    return math.abs(a - b) < L_EPSILON
end

local function calculate_highlight_stack(subs, sub_idx, token_idx, time_pos)
    if not next(FSM.ANKI_HIGHLIGHTS) or not subs or not subs[sub_idx] then return 0, 0, false, {}, 0 end
    
    local tokens = get_sub_tokens(subs[sub_idx])
    if not tokens then return 0, 0, 0, false end
    
    local target_token = tokens[token_idx]
    if not target_token or not target_token.is_word then return 0, 0, false, {}, 0 end
    
    local target_l_idx = target_token.logical_idx
    local target_word_text = target_token.text
    local target_lower_full = utf8_to_lower(target_word_text:gsub("[%p%s]", ""))
    if target_lower_full == "" then return 0, 0, false, {}, 0 end

    -- Extract subwords for partial matches within compounds (e.g. Netto/Globus, 20–25)
    local target_subsets = { [target_lower_full] = true }
    for sw in target_word_text:gmatch("[^%s/-\226\128\147\226\128\148]+") do
        local csw = utf8_to_lower(sw:gsub("[%p%s]", ""))
        if csw ~= "" then target_subsets[csw] = true end
    end

    -- Helper to get a word by relative LOGICAL offset
    local function get_relative_word_text(rel_logical_offset)
        local curr_s_idx = sub_idx
        local target_logical_idx = target_l_idx + rel_logical_offset
        
        local safety = 0
        local safety_limit = Options.anki_split_search_window or 20
        while safety < safety_limit do
            safety = safety + 1
            local c_tokens = get_sub_tokens(subs[curr_s_idx])
            if not c_tokens then return nil end
            
            for _, t in ipairs(c_tokens) do
                if logical_cmp(t.logical_idx, target_logical_idx) then
                    return t.text
                end
            end
            
            -- Bounds check to move segments
            local wc = subs[curr_s_idx].word_count or 0
            if target_logical_idx > wc then
                target_logical_idx = target_logical_idx - wc
                curr_s_idx = curr_s_idx + 1
                if not subs[curr_s_idx] or not subs[curr_s_idx-1] or (subs[curr_s_idx].start_time - subs[curr_s_idx-1].end_time > (Options.anki_split_gap_limit or 10.0)) then return nil end
            elseif target_logical_idx < 1 then
                curr_s_idx = curr_s_idx - 1
                if not subs[curr_s_idx] or not subs[curr_s_idx+1] or (subs[curr_s_idx+1].start_time - subs[curr_s_idx].end_time > (Options.anki_split_gap_limit or 10.0)) then return nil end
                get_sub_tokens(subs[curr_s_idx]) -- Ensure word_count is cached
                target_logical_idx = target_logical_idx + (subs[curr_s_idx].word_count or 0)
            else
                return nil
            end
        end
        return nil
    end

    local orange_stack = 0
    local purple_stack = 0
    local purple_depth = 0
    local has_phrase = false
    local matched_terms = {}
    local matching_source_terms = {}
    for _, data in ipairs(FSM.ANKI_HIGHLIGHTS) do
        local term_key = data.term
        if not matched_terms[term_key] then
            local match_found = false
            local term_is_split = false
            local term_is_local_split = false
            
            -- Performance: Lazy-cache processed term data
            if not data.__term_clean then
                data.__is_elliptical = term_key:find("...", 1, true) ~= nil
                local term_tokens = build_word_list_internal(utf8_to_lower(term_key), false)
                data.__term_clean = {}
                for _, t in ipairs(term_tokens) do
                    if t.is_word then
                        table.insert(data.__term_clean, utf8_to_lower(t.text:gsub("[%p%s]", "")))
                    end
                end
                -- First extract cloze content (e.g., {{c1::hello}} -> hello), THEN strip standard ASS tags {...}
                local cleaned_ctx = data.context:gsub("{{c%d+::(.-)}}", "%1"):gsub("{[^}]+}", "")
                data.__ctx_lower = utf8_to_lower(cleaned_ctx)
                
                -- Tokenize context for exact neighbor matching (prevents substring bleed)
                data.__ctx_words = {}
                local ctx_tokens = build_word_list_internal(data.__ctx_lower, false)
                for _, t in ipairs(ctx_tokens) do
                    if t.is_word then
                        data.__ctx_words[utf8_to_lower(t.text:gsub("[%p%s]", ""))] = true
                    end
                end

                -- Parse string indices (if not already parsed during load)
                if data.index and not data.__pivots then
                    data.__pivots = {}
                    for part in (tostring(data.index) .. ","):gmatch("([^,]*),") do
                        local l_off, p_idx, t_pos = part:match("^([%-+]?%d+):(%d+%.?%d*):(%d+)$")
                        if l_off then
                            table.insert(data.__pivots, {l_off = tonumber(l_off), p_idx = tonumber(p_idx), t_pos = tonumber(t_pos)})
                        else
                            local single = tonumber(part)
                            if single then table.insert(data.__pivots, {l_off = 0, p_idx = single, t_pos = 1}) end
                        end
                    end
                end
            end
            local term_clean = data.__term_clean
            
            local window = Options.anki_local_fuzzy_window
            if #term_clean > 10 then window = window + ((#term_clean - 10) * 0.5) end

            local sub_start = subs[sub_idx].start_time
            local sub_end = subs[sub_idx].end_time

            local in_window = false
            if Options.anki_global_highlight or (data.time >= sub_start - window and data.time <= sub_end + window) then
                in_window = true
            elseif #term_clean > 1 then
                local scan_padding = Options.anki_split_search_window or 15
                local min_scan = math.max(1, sub_idx - scan_padding)
                local max_scan = math.min(#subs, sub_idx + scan_padding)
                if data.time >= (subs[min_scan].start_time - window) and data.time <= (subs[max_scan].end_time + window) then
                    in_window = true
                end
            end

            if in_window then
                -- Global Footprint Shadow Check (Nesting & Background Intersections)
                if data.__min_l then
                    local t_center = data.__cached_anchor_sub
                    if not t_center or data.__cached_time ~= data.time then
                        t_center = get_center_index(subs, data.time)
                        data.__cached_anchor_sub = t_center
                        data.__cached_time = data.time
                    end
                    if t_center ~= -1 then
                        local t_start = (t_center + data.__min_l) * 1000 + data.__min_w
                        local t_end = (t_center + data.__max_l) * 1000 + data.__max_w
                        local t_total = sub_idx * 1000 + target_l_idx
                        if t_total >= t_start and t_total <= t_end then
                            purple_depth = purple_depth + 1
                        end
                    end
                end

                local target_offsets = {}
                for term_offset, tw_clean in ipairs(term_clean) do
                    if target_subsets[tw_clean] then
                        table.insert(target_offsets, term_offset)
                    end
                end

                if #target_offsets > 0 then
                    local any_sequence = false
                    for _, term_offset in ipairs(target_offsets) do
                        local sequence_match = true
                        
                        -- Phase 1: Local Sequence Match via Logical Indices
                        if data.__is_elliptical then
                            sequence_match = false
                        elseif #term_clean > 1 then
                            for k = 1, #term_clean do
                                if k ~= term_offset then
                                    local rw_text = get_relative_word_text(k - term_offset)
                                    if not rw_text or term_clean[k] ~= utf8_to_lower(rw_text:gsub("[%p%s]", "")) then
                                        sequence_match = false
                                        break
                                    end
                                end
                            end
                        end

                        -- Phase 2: Context Grounding
                        local context_satisfied = false
                        
                        if Options.anki_global_highlight then
                            -- In Global Mode, single words should highlight with high recall.
                            -- Neighborhood verification is prioritized for multi-word phrases
                            -- to prevent coincidental cross-scene matching.
                            local needs_strict = Options.anki_context_strict and (#term_clean > 1)
                            if needs_strict then
                                -- Robust neighbor check for Global Mode
                                local match_count = 0
                                local scan_pad = Options.anki_neighbor_window or 5
                                for s_off = -scan_pad, scan_pad do
                                    local scan_sub = subs[sub_idx + s_off]
                                    if scan_sub then
                                        local s_tokens = get_sub_tokens(scan_sub)
                                        if s_tokens then
                                            for _, t in ipairs(s_tokens) do
                                                if t.is_word then
                                                    local cw = utf8_to_lower(t.text:gsub("[%p%s]", ""))
                                                    -- Match if a meaningful context word is found (exact match, excluding the search term itself)
                                                    if #cw >= 2 and data.__ctx_words[cw] then
                                                        local is_term = false
                                                        for _, tw in ipairs(term_clean) do
                                                            if tw == cw then is_term = true; break end
                                                        end
                                                        if not is_term then
                                                            match_count = match_count + 1
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        if match_count >= 1 then break end
                                    end
                                end
                                context_satisfied = (match_count >= 1)
                            else
                                context_satisfied = true
                            end
                        else
                            -- Local Mode (Global OFF): MUST be grounded if pivots exist
                            if data.__pivots and #data.__pivots > 0 then
                                local origin_l = get_center_index(subs, data.time)
                                if origin_l ~= -1 then
                                    -- Verify the specific pivot corresponding to this word part
                                    local g = data.__pivots[term_offset]
                                    if g then
                                        -- Apply +/- 1 segment drift tolerance to absorb +1ms temporal epsilon boundaries
                                        local line_match = math.abs(sub_idx - (origin_l + g.l_off)) <= 1
                                        if line_match and target_l_idx == g.p_idx then
                                            context_satisfied = true
                                        end
                                    end
                                end
                            else
                                -- Legacy records or no index: tight time window already satisfied by Phase 0 loop
                                context_satisfied = true
                            end
                        end

                        if sequence_match and context_satisfied then
                            any_sequence = true
                            break
                        end
                    end

                    if any_sequence then
                        match_found = true
                        if #term_clean > 1 then has_phrase = true end
                    end

                    -- Phase 3: Split Matching (Only if not already matched as contiguous, and is multi-word)
                    if not match_found and #term_clean > 1 then
                        local origin_sub_idx = Options.anki_global_highlight and sub_idx or get_center_index(subs, data.time)
                        if not subs[sub_idx].__split_valid_indices then
                            subs[sub_idx].__split_valid_indices = {}
                        end
                        local valid_set = subs[sub_idx].__split_valid_indices[term_key]
                        
                        if valid_set == nil then
                            valid_set = false
                            local ctx_list = {}
                            local s_start = math.max(1, math.min(sub_idx, origin_sub_idx) - Options.anki_split_search_window)
                            local s_end = math.min(#subs, math.max(sub_idx, origin_sub_idx) + Options.anki_split_search_window)

                            for scan_i = s_start, s_end do
                                local scan_tokens = get_sub_tokens(subs[scan_i])
                                if scan_tokens then
                                    local gap = math.abs(subs[scan_i].start_time - data.time)
                                    if Options.anki_global_highlight or gap < Options.anki_split_gap_limit then
                                        for t_i, t in ipairs(scan_tokens) do
                                            if t.is_word then
                                                local cw = utf8_to_lower(t.text:gsub("[%p%s]", ""))
                                                if cw ~= "" then
                                                    table.insert(ctx_list, {cw=cw, s_i=scan_i, t_i=t_i, l_i=t.logical_idx, start=subs[scan_i].start_time})
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            local occs = {}
                            local all_present = true
                            for i_c, tc in ipairs(term_clean) do
                                occs[i_c] = {}
                                for c_idx, cw_obj in ipairs(ctx_list) do
                                    if cw_obj.cw == tc then table.insert(occs[i_c], c_idx) end
                                end
                                if #occs[i_c] == 0 then all_present = false break end
                            end

                            if all_present then
                                local best_tuple = nil
                                local min_span = 999999
                                local best_unanchored_tuple = nil
                                local min_unanchored_span = 999999
                                
                                local function search(term_idx, current_tuple)
                                    if term_idx > #term_clean then
                                        local valid_timing = true
                                        local has_anchor = (not data.index) or (data.index == -1) or (origin_sub_idx == -1) or Options.anki_global_highlight
                                        for m_idx = 1, #current_tuple do
                                            local m = ctx_list[current_tuple[m_idx]]
                                            if m_idx > 1 then
                                                local prev_m = ctx_list[current_tuple[m_idx-1]]
                                                if math.abs(m.start - prev_m.start) > Options.anki_split_gap_limit then
                                                    valid_timing = false; break
                                                end
                                            end
                                            if data.__pivots and #data.__pivots > 0 then
                                                local all_pivots_matched = true
                                                for _, g in ipairs(data.__pivots) do
                                                    local m = ctx_list[current_tuple[g.t_pos]]
                                                    -- Apply +/- 1 segment drift tolerance
                                                    local line_match = m and math.abs(m.s_i - (origin_sub_idx + g.l_off)) <= 1
                                                    if not (line_match and m.l_i == g.p_idx) then
                                                        all_pivots_matched = false; break
                                                    end
                                                end
                                                if all_pivots_matched then has_anchor = true end
                                            end
                                        end
                                        
                                        if valid_timing then
                                            local span = current_tuple[#current_tuple] - current_tuple[1]
                                            if has_anchor then
                                                if span < min_span then
                                                    min_span = span
                                                    best_tuple = {}
                                                    for k,v in ipairs(current_tuple) do best_tuple[k] = v end
                                                end
                                            else
                                                if span < min_unanchored_span then
                                                    min_unanchored_span = span
                                                    best_unanchored_tuple = {}
                                                    for k,v in ipairs(current_tuple) do best_unanchored_tuple[k] = v end
                                                end
                                            end
                                        end
                                        return
                                    end
                                    local prev_idx = (term_idx == 1) and 0 or current_tuple[term_idx - 1]
                                    for _, c_idx in ipairs(occs[term_idx]) do
                                        if c_idx > prev_idx then
                                            current_tuple[term_idx] = c_idx
                                            search(term_idx + 1, current_tuple)
                                        end
                                    end
                                end
                                search(1, {})
                                
                                -- Fallback to unanchored match only if Global Mode is ON, at original time, or no ground-truth available
                                if not best_tuple and best_unanchored_tuple then
                                    if Options.anki_global_highlight or (origin_sub_idx ~= -1) or not (data.__pivots and #data.__pivots > 0) then
                                        best_tuple = best_unanchored_tuple
                                    end
                                end
                                
                                 if best_tuple then
                                    local is_all_local = true
                                    for _, c_idx in ipairs(best_tuple) do
                                        if ctx_list[c_idx].s_i ~= sub_idx then
                                            is_all_local = false; break
                                        end
                                    end
                                    valid_set = { is_local = is_all_local, indices = {} }
                                    local min_idx = math.huge
                                    local max_idx = 0
                                    for _, c_idx in ipairs(best_tuple) do
                                        local cw_obj = ctx_list[c_idx]
                                        valid_set.indices[cw_obj.s_i .. "-" .. cw_obj.t_i] = true
                                        local total_val = cw_obj.s_i * 1000 + cw_obj.l_i
                                        if total_val < min_idx then min_idx = total_val end
                                        if total_val > max_idx then max_idx = total_val end
                                    end
                                    valid_set.min_idx = min_idx
                                    valid_set.max_idx = max_idx
                                end
                            end
                            subs[sub_idx].__split_valid_indices[term_key] = valid_set
                        end
                        
                        if valid_set then
                            if valid_set.indices[sub_idx .. "-" .. token_idx] then
                                match_found = true
                                term_is_split = true
                            end

                            local t_total = sub_idx * 1000 + target_l_idx
                            if t_total >= valid_set.min_idx and t_total <= valid_set.max_idx then
                                -- Handled by unified shadow check above
                            end
                        end
                    end
                end
            end

            if match_found then
                if term_is_split then 
                    purple_stack = purple_stack + 1
                    if #term_clean > 1 then has_phrase = true end
                else 
                    orange_stack = orange_stack + 1 
                end
                matched_terms[term_key] = true
                table.insert(matching_source_terms, {text = data.term, is_split = term_is_split})
            end
        end
    end
    return orange_stack, purple_stack, has_phrase, matching_source_terms, purple_depth
end

local function get_word_boundary(q_table, pos, direction)
    -- direction: -1 (left), 1 (right)
    if #q_table == 0 then return 0 end
    
    local new_pos = pos

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



local function starts_with_uppercase(str)
    if not str or str == "" then return false end
    local first_char = str:match("^([%z\1-\127\194-\244][\128-\191]*)")
    if not first_char then return false end
    if first_char:match("^[A-Z]") then return true end
    
    local upper = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ"
    for ch in string.gmatch(upper, "[%z\1-\127\194-\244][\128-\191]*") do
        if first_char == ch then return true end
    end
    return false
end

local function extract_anki_context(full_line, selected_term, max_words_override, pivot_pos, coord_map)
    if not full_line or full_line == "" then return "" end
    if not selected_term or selected_term == "" then return full_line end
    
    -- 1. Try to find the occurrence closest to the pivot position (or center if not provided).
    -- This handles ambiguous common words (e.g. "die") when multiple context lines are present.
    -- If coord_map is provided (Gap 1 compliance), we prioritize logical grounding.
    local term_lower = selected_term:lower()
    local full_lower = full_line:lower()
    local center = pivot_pos or (#full_line / 2)
    local start_pos, end_pos = nil, nil
    local best_dist = math.huge
    local search_from = 1
    
    print(string.format("[LLS] Search Pivot: %.1f | Term: '%s' | Text Len: %d", center, selected_term, #full_line))
    while true do
        local s, e = full_lower:find(term_lower, search_from, true)
        if not s then break end
        local dist = math.abs((s + e) / 2 - center)
        print(string.format("  - Candidate at %d-%d | Dist: %.1f", s, e, dist))
        if dist < best_dist then
            best_dist = dist
            start_pos, end_pos = s, e
        end
        search_from = math.max(search_from + 1, e + 1)
    end
    if start_pos then print(string.format("  - Selected match at index %d", start_pos)) end
    
    -- Non-contiguous term fallback: the composed term can't be found verbatim
    -- (words were skipped between picks, or picks span sentence boundaries).
    -- Anchor accurately by finding the occurrence of EVERY word in the term
    -- that is closest to the blob center, then using the min-start and max-end
    -- of those matches as the search span. This ensures that selections spanning
    -- across sentence boundaries (e.g. "und ... Ende") correctly capture all
    -- involved sentences.
    if not start_pos then
        -- Sequential forward search: find the first word closest to the pivot,
        -- then find each subsequent word strictly after the previous match.
        -- This preserves the document order of the original selection and avoids
        -- picking an earlier occurrence of a later word (e.g. "bag six" instead of "six five four").
        local seq_pos = 1
        local first_word_found = false
        local min_s, max_e = nil, nil
        
        for word in term_lower:gmatch("%S+") do
            if word ~= "..." then
                if not first_word_found then
                    -- For the first real word, pick the occurrence closest to the pivot
                    local best_ws, best_we = nil, nil
                    local best_dist_word = math.huge
                    local s_from = 1
                    while true do
                        local ws, we = full_lower:find(word, s_from, true)
                        if not ws then break end
                        local dist = math.abs((ws + we) / 2 - center)
                        if dist < best_dist_word then
                            best_dist_word = dist
                            best_ws, best_we = ws, we
                        end
                        s_from = math.max(s_from + 1, we + 1)
                    end
                    if best_ws then
                        min_s = best_ws
                        max_e = best_we
                        seq_pos = best_we + 1
                        first_word_found = true
                    end
                else
                    -- For subsequent words, search strictly forward from the previous match
                    local ws, we = full_lower:find(word, seq_pos, true)
                    if ws then
                        max_e = we
                        seq_pos = we + 1
                    end
                end
            end
        end
        
        if min_s then
            start_pos, end_pos = min_s, max_e
        end
    end
    
    local sentence = full_line
    local sent_start = 1
    local sent_end = #full_line
    local sentence_abs_start = 1   -- tracks where the cleaned sentence starts in full_line
    
    if start_pos then
        -- Search backwards for subtitle boundary (NUL sentinel)
        local pre = full_line:sub(1, start_pos - 1)
        local b_idx = pre:reverse():find("\0", 1, true)
        if b_idx then
            sent_start = start_pos - b_idx + 1
        else
            sent_start = 1
        end
        
        -- Search forwards for subtitle boundary
        local post = full_line:sub(end_pos + 1)
        local f_idx = post:find("\0", 1, true)
        if f_idx then
            sent_end = end_pos + f_idx
        end
        
        local raw_sub = full_line:sub(sent_start, sent_end)
        -- Replace sentinels with spaces and trim
        sentence = raw_sub:gsub("%z", " "):match("^%s*(.-)%s*$") or ""
        
        -- Track where the cleaned sentence actually begins in full_line (for truncation offset math)
        local lead = raw_sub:match("^([%s%z]*)") or ""
        sentence_abs_start = sent_start + #lead
    end

    -- 2. Check word count of the extracted sentence.
    local words = build_word_list(sentence)
    local limit = max_words_override or Options.anki_context_max_words
    if #words <= limit then return sentence end
    
    -- 3. If the sentence is still too long, truncate around the selected span.
    -- Use the pre-computed sentence_abs_start so the "." append doesn't break offset math.
    local first_idx, last_idx = nil, nil
    if start_pos then
        local s_rel = start_pos - sentence_abs_start + 1
        local e_rel = end_pos   - sentence_abs_start + 1
        s_rel = math.max(1, s_rel)
        e_rel = math.max(s_rel, e_rel)
        
        local curr_char = 1
        for i, w in ipairs(words) do
            local w_start = sentence:find(w, curr_char, true)
            if w_start then
                local w_end = w_start + #w - 1
                if w_end >= s_rel and w_start <= e_rel then
                    first_idx = first_idx or i
                    last_idx = i
                end
                curr_char = w_end + 1
            end
        end
        
        print(string.format("[LLS] Truncation Trace: Words: %d | Limit: %d | s_rel: %d | e_rel: %d", #words, limit, s_rel, e_rel))
    else
        print(string.format("[LLS] Truncation Trace: Words: %d | Limit: %d | no anchor", #words, limit))
    end
    if first_idx then
        print(string.format("  - Span Detected: Word %d to %d", first_idx, last_idx))
    else
        print("  - FAILED to detect span, falling back to full sentence")
        return sentence
    end
    
    -- If the selection span itself is wider than the limit, the user picked words far apart —
    -- return the full sentence so none of the picked words are hidden.
    local span = last_idx - first_idx + 1
    if span >= limit then
        -- Selection spans more words than the limit allows padding for.
        -- Crop to the span but add a small fixed padding on each side so the
        -- extreme selected words don't get cut mid-phrase.
        local pad = Options.anki_context_span_pad
        local crop_start = math.max(1, first_idx - pad)
        local crop_end   = math.min(#words, last_idx + pad)
        print(string.format("  - Span (%d) >= limit (%d), cropping to span+pad [%d..%d]", span, limit, crop_start, crop_end))
        local span_words = {}
        for i = crop_start, crop_end do table.insert(span_words, words[i]) end
        return compose_term_smart(span_words):match("^%s*(.-)%s*$")
    end
    
    -- Center the viewport around the detected span
    local center_idx = math.floor((first_idx + last_idx) / 2)
    local half_max = math.floor(limit / 2)
    local context_start = math.max(1, center_idx - half_max)
    local context_end = math.min(#words, center_idx + half_max)
    
    -- Shift viewport to ensure the full core span is visible
    if context_start > first_idx then
        local shift = context_start - first_idx
        context_start = first_idx
        context_end = math.max(context_start, context_end - shift)
    end
    if context_end < last_idx then
        local shift = last_idx - context_end
        context_end = last_idx
        context_start = math.max(1, context_start - shift)
    end
    
    print(string.format("  - Viewport: %d to %d (Center: %d)", context_start, context_end, center_idx))
    
    local context_words = {}
    for i = context_start, context_end do table.insert(context_words, words[i]) end
    
    return compose_term_smart(context_words):match("^%s*(.-)%s*$")
end



local function get_tsv_path()
    local path = mp.get_property("path")
    if not path then return nil end
    local base = path:match("(.+)%.[^%.]+$")
    if not base then base = path end
    return base .. ".tsv"
end

local function cmd_open_record_file()
    local path = get_tsv_path()
    if not path then
        mp.msg.info("OPEN-RECORD: no media loaded")
        return
    end

    local f = io.open(path, "r")
    if not f then
        mp.msg.info("OPEN-RECORD: file not found: " .. tostring(path))
        show_osd("No record file found")
        return
    end
    f:close()

    local editor = Options.record_editor
    if not editor or editor == "" then
        mp.msg.info("OPEN-RECORD: record_editor not configured")
        show_osd("Set lls-record_editor in mpv.conf")
        return
    end

    mp.msg.info("OPEN-RECORD: launching [" .. editor .. "] with [" .. path .. "]")
    mp.command_native_async({
        name = "subprocess",
        args = {editor, path},
        playback_only = false,
        detach = true
    }, function(success, result, err)
        if err then mp.msg.warn("OPEN-RECORD error: " .. tostring(err)) end
    end)
end

local function load_anki_tsv(force)
    local tsv_path = get_tsv_path()
    if not tsv_path then return end
    
    local info = utils.file_info(tsv_path)
    local fingerprint_match = info and (info.mtime == FSM.ANKI_DB_MTIME) and (info.size == FSM.ANKI_DB_SIZE)

    if FSM.ANKI_DB_PATH ~= tsv_path then
        FSM.ANKI_DB_PATH = tsv_path
        FSM.ANKI_HIGHLIGHTS = {}
        FSM.ANKI_DB_MTIME = 0
        FSM.ANKI_DB_SIZE = 0
        fingerprint_match = false
    end

    if fingerprint_match and not force and next(FSM.ANKI_HIGHLIGHTS) ~= nil then
        -- Fingerprint matches and we have data: skip expensive reload
        return 
    end

    -- Load config before attempting file open so the auto-created header
    -- matches the actual anki_mapping.ini field names, not hardcoded defaults.
    local config = load_anki_mapping_ini()

    local term_cols = {}
    local ctx_cols = {}
    local time_col = 3
    local index_col = -1
    if #config.fields > 0 then
        for i, fld in ipairs(config.fields) do
            local src = config.mapping[fld] or config.mapping_word[fld] or config.mapping_sentence[fld]
            if src == "source_word" then table.insert(term_cols, i)
            elseif src == "source_sentence" then table.insert(ctx_cols, i)
            elseif src == "time" then time_col = i
            elseif src == "source_index" then index_col = i end
        end
    end
    if #term_cols == 0 then table.insert(term_cols, 1) end
    if #ctx_cols == 0 then table.insert(ctx_cols, 2) end

    local term_header_name = nil
    if config.fields and term_cols[1] and config.fields[term_cols[1]] then
        term_header_name = config.fields[term_cols[1]]
    end

    local f = io.open(tsv_path, "r")
    if not f then
        FSM.ANKI_HIGHLIGHTS = {}
        print("[LLS] TSV file missing - attempting auto-creation: " .. tostring(tsv_path))
        
        -- Build header from actual config fields; fall back to generic defaults
        -- if no mapping is configured. This mirrors save_anki_tsv_row's header logic.
        local header_line
        if #config.fields > 0 then
            header_line = table.concat(config.fields, "\t")
        else
            header_line = "Term\tSentence\tTime"
        end

        -- Find the deck column index (same logic as save_anki_tsv_row)
        local deck_col = -1
        for i, fld in ipairs(config.fields) do
            local src = config.mapping[fld] or config.mapping_word[fld] or config.mapping_sentence[fld]
            if src == "deck_name" then
                deck_col = i
                break
            end
        end

        local wf = io.open(tsv_path, "w")
        if wf then
            -- Write #deck directive first, then field headers — matches save_anki_tsv_row order
            if deck_col > 0 then
                wf:write(string.format("#deck column:%d\n", deck_col))
            end
            wf:write(header_line .. "\n")
            wf:close()
            f = io.open(tsv_path, "r") -- Re-open for reading
            if not f then 
                print("[LLS] TSV creation failed - path may be read-only")
                return 
            end
        else
            print("[LLS] TSV creation failed - could not open for writing")
            return 
        end
    end


    local new_highlights = {}

    for line in f:lines() do
        if not line:match("^#") then
            local fields = {}
            for field in (line .. "\t"):gmatch("([^\t]*)\t") do
                table.insert(fields, field)
            end
            -- Check time boundary minimums
            if #fields > 0 then
                local t = ""
                for _, col_idx in ipairs(term_cols) do
                    if fields[col_idx] and fields[col_idx] ~= "" then
                        t = fields[col_idx]
                        break
                    end
                end
                
                local c = ""
                for _, col_idx in ipairs(ctx_cols) do
                    if fields[col_idx] and fields[col_idx] ~= "" then
                        c = fields[col_idx]
                        break
                    end
                end

                -- If the TSV row did not export the term (e.g. phrase cards with no WordSource),
                -- we simply fall back to treating the entire SentenceSource context as the highlight target!
                if t == "" and c ~= "" then
                    t = c
                end

                local time_val = tonumber(fields[time_col])
                if not time_val or time_val <= 0 then
                    for k = #fields, math.max(1, #fields - 10), -1 do
                        if tonumber(fields[k]) and tostring(fields[k]):match("^%d+%.%d+$") then
                            time_val = tonumber(fields[k])
                            break
                        end
                    end
                    time_val = time_val or 0
                end
                
                local idx_val = (index_col > 0) and fields[index_col] or nil
                if type(idx_val) == "string" then idx_val = idx_val:gsub("\r", "") end
                if idx_val == "" then idx_val = nil end
                -- Try to convert to number only if it's a simple integer; otherwise keep as grounding string
                if idx_val and idx_val:match("^%-?%d+$") then
                    idx_val = tonumber(idx_val)
                end
                
                local is_header = (t == "WordSource" or t == "Term" or (term_header_name and t == term_header_name))
                if t and t ~= "" and not is_header then
                    local data = { term = t, context = c, time = time_val, index = idx_val }
                    -- Pre-parse Advanced Pivot Grounding coordinates (Multi-Anchor support)
                    if idx_val then
                        data.__pivots = {}
                        local min_l = math.huge
                        local max_l = -math.huge
                        local min_w = 1000
                        local max_w = 0
                        
                        for part in (tostring(idx_val) .. ","):gmatch("([^,]*),") do
                            local l_off, p_idx, t_pos = part:match("^([%-+]?%d+):(%d+%.?%d*):(%d+)$")
                            if l_off then
                                local r_l = tonumber(l_off)
                                local r_w = tonumber(p_idx)
                                table.insert(data.__pivots, {l_off = r_l, p_idx = r_w, t_pos = tonumber(t_pos)})
                                
                                if r_l < min_l then min_l = r_l; min_w = r_w
                                elseif r_l == min_l then if r_w < min_w then min_w = r_w end end
                                
                                if r_l > max_l then max_l = r_l; max_w = r_w
                                elseif r_l == max_l then if r_w > max_w then max_w = r_w end end
                            else
                                local single = tonumber(part)
                                if single then 
                                    table.insert(data.__pivots, {l_off = 0, p_idx = single, t_pos = 1}) 
                                    if 0 < min_l then min_l = 0; min_w = single end
                                    if 0 > max_l then max_l = 0; max_w = single end
                                    if single < min_w and min_l == 0 then min_w = single end
                                    if single > max_w and max_l == 0 then max_w = single end
                                end
                            end
                        end
                        data.__min_l = (min_l == math.huge) and 0 or min_l
                        data.__max_l = (max_l == -math.huge) and 0 or max_l
                        data.__min_w = min_w
                        data.__max_w = max_w
                    end
                    table.insert(new_highlights, data)
                end
            end
        end
    end
    f:close()
    
    FSM.ANKI_HIGHLIGHTS = new_highlights
    
    -- Update fingerprint for next time after successful load
    if info then
        FSM.ANKI_DB_MTIME = info.mtime
        FSM.ANKI_DB_SIZE = info.size
    end
    print(string.format("[LLS] TSV Loaded: %d highlights (mtime=%s, size=%s)", #new_highlights, tostring(FSM.ANKI_DB_MTIME), tostring(FSM.ANKI_DB_SIZE)))
end

local function save_anki_tsv_row(term, context, time_pos, item_index)
    local tsv_path = get_tsv_path()
    if not tsv_path then return end

    local config = load_anki_mapping_ini()
    local settings = config.settings
    
    -- Calculate word count to determine profile
    local term_words = build_word_list(term)
    local term_word_count = #term_words
    local threshold = tonumber(settings.sentence_word_threshold) or Options.sentence_word_threshold or 3
    
    local is_sentence = (term_word_count >= threshold)
    local fields = config.fields
    local mapping = config.mapping

    if is_sentence then
        if next(config.mapping_sentence) then mapping = config.mapping_sentence end
    else
        if next(config.mapping_word) then mapping = config.mapping_word end
    end
    
    local tts = config.tts

    if #fields == 0 then
        -- Fallback default behavior
        fields = {"Term", "Context"}
        mapping = {Term = "source_word", Context = "source_sentence"}
    end

    local deck_name, pri_lang, sec_lang = "", "", ""
    if Tracks.pri.path then
        deck_name, pri_lang = extract_subtitle_metadata(Tracks.pri.path)
    end
    if Tracks.sec.path then
        local _, s_lang = extract_subtitle_metadata(Tracks.sec.path)
        sec_lang = s_lang
    end
    if settings.deck_name and settings.deck_name ~= "" then
        deck_name = settings.deck_name
    end

    local f_check = io.open(tsv_path, "r")
    local exists = (f_check ~= nil)
    local is_empty = true
    if exists then 
        local content = f_check:read(1)
        if content then is_empty = false end
        f_check:close() 
    end

    local f = io.open(tsv_path, "a")
    if not f then return end

    if not exists or is_empty then
        local deck_col = -1
        for i, fld in ipairs(fields) do
            if mapping[fld] == "deck_name" then
                deck_col = i
                break
            end
        end
        
        -- 1. Write the #deck directive if possible
        if deck_col > 0 then
            f:write(string.format("#deck column:%d\n", deck_col))
        end
        
        -- 2. ALWAYS write the field list as headers for Anki mapping clarity
        if #fields > 0 then
            f:write(table.concat(fields, "\t") .. "\n")
        end
    end

    local row_data = {}
    for i, field_name in ipairs(fields) do
        if field_name == "" then
            table.insert(row_data, "")
        else
            table.insert(row_data, resolve_anki_field(field_name, term, context, time_pos, deck_name, pri_lang, sec_lang, mapping, tts, item_index))
        end
    end
    
    f:write(table.concat(row_data, "\t") .. "\n")
    f:close()

    table.insert(FSM.ANKI_HIGHLIGHTS, { term = term, context = context, time = time_pos, index = item_index })
    
    -- Performance Optimization: Update fingerprints so the next periodic sync 
    -- doesn't trigger a redundant re-parse for this local change.
    local info = utils.file_info(tsv_path)
    if info then
        FSM.ANKI_DB_MTIME = info.mtime
        FSM.ANKI_DB_SIZE = info.size
    end
end




-- =========================================================================
-- FSM INTERNAL LOGIC
-- =========================================================================

local function update_font_scale()
    local dim = mp.get_property_native("osd-dimensions")
    if not dim or dim.h == 0 then return end
    
    local is_ass = false
    local track_list = mp.get_property_native("track-list")
    
    if track_list then
        for _, track in ipairs(track_list) do
            if track.type == "sub" and track.selected then
                if track.codec == "ass" or track.codec == "ssa" then
                    is_ass = true
                end
                break
            end
        end
    end

    if is_ass then
        mp.set_property_number("sub-scale", 1.0)
    else
        local comp_scale = 1.0
        if dim.h < Options.font_base_height then
            local perfect_comp = Options.font_base_height / dim.h
            comp_scale = 1.0 + (perfect_comp - 1.0) * Options.font_scale_strength
        end
        mp.set_property_number("sub-scale", comp_scale * Options.font_base_scale)
    end
end

local function update_media_state()
    load_anki_tsv()
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

    -- Flush stale drum subs and selection when track path changed or track was disabled
    if Tracks.pri.path ~= old_pri_path then 
        Tracks.pri.subs = {} 
        FSM.DW_CURSOR_LINE = -1
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_CURSOR_X = nil
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        FSM.DW_LAYOUT_CACHE = nil
    end
    if Tracks.sec.path ~= old_sec_path then Tracks.sec.subs = {} end

    -- Load subtitles for logic memory if necessary (always eager to support global navigation)
    if Tracks.pri.path and #Tracks.pri.subs == 0 then
        Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
    end
    if Tracks.sec.path and #Tracks.sec.subs == 0 then
        Tracks.sec.subs = load_sub(Tracks.sec.path, Tracks.sec.is_ass)
    end

    -- Determine State
    if Tracks.pri.id == 0 and Tracks.sec.id == 0 then
        FSM.MEDIA_STATE = "NO_SUBS"
    elseif Tracks.sec.id == 0 then
        FSM.MEDIA_STATE = Tracks.pri.is_ass and "SINGLE_ASS" or "SINGLE_SRT"
    elseif Tracks.pri.id == 0 then
        FSM.MEDIA_STATE = Tracks.sec.is_ass and "SINGLE_ASS" or "SINGLE_SRT"
    else
        if Tracks.pri.is_ass and Tracks.sec.id ~= 0 and Tracks.sec.is_ass then
            FSM.MEDIA_STATE = "DUAL_ASS"
        elseif not Tracks.pri.is_ass and (Tracks.sec.id == 0 or not Tracks.sec.is_ass) then
            FSM.MEDIA_STATE = "DUAL_SRT"
        else
            FSM.MEDIA_STATE = "DUAL_MIXED"
        end
    end
    update_interactive_bindings()

    -- If Drum Mode is ON, but MEDIA_STATE includes an ASS track, we MUST disable Drum Mode to prevent bugs
    if FSM.DRUM == "ON" then
        if FSM.MEDIA_STATE:match("ASS") then
            FSM.DRUM = "OFF"
            if FSM.DRUM_WINDOW == "OFF" then
                mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
                mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
                mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
            end
            drum_osd.data = ""
            drum_osd:update()
            show_osd("Drum Mode: AUTO-DISABLED (ASS Track Loaded)", Options.osd_duration + 1.0)
        end
    end
end

-- =========================================================================
-- HIGHLIGHT RENDERING UTILS
-- =========================================================================

local function format_highlighted_word(word, h_color, base_color, is_phrase, bold_state, use_1c)
    if type(word) == "table" then word = word.text end
    if not word then return "" end
    
    local c_tag = use_1c and "1c" or "c"
    local b_on = Options.anki_highlight_bold and "{\\b1}" or ""
    local b_off = Options.anki_highlight_bold and string.format("{\\b%s}", bold_state or "0") or ""
    
    if (h_color == base_color) then return word end

    if is_phrase then
        -- Full highlighting for phrases (continuous flow)
        return string.format("%s{\\%s&H%s&}%s{\\%s&H%s&}%s", b_on, c_tag, h_color, word, c_tag, base_color, b_off)
    else
        -- Surgical highlighting for single words (professional look: punctuation uncolored)
        local pre = word:match("^[%p%s]*")
        local suf = word:match("[%p%s]*$")
        local mid = ""
        if #pre < #word then
            mid = word:sub(#pre + 1, #word - #suf)
        end
        if mid ~= "" then
            return string.format("%s%s{\\%s&H%s&}%s%s{\\%s&H%s&}%s", pre, b_on, c_tag, h_color, mid, b_off, c_tag, base_color, suf)
        else
            return word
        end
    end
end

-- =========================================================================
-- DRUM RENDERER
-- =========================================================================

-- Helper to estimate the width of a proportional string
local function dw_get_str_width(str, fs, font_name)
    if type(str) == "table" then str = str.text end
    if not str then return 0 end
    fs = fs or Options.dw_font_size
    font_name = font_name or Options.dw_font_name
    
    -- Strip ASS tags before calculating physical width
    str = str:gsub("{[^}]+}", "")
    
    -- Monospace path (standard for Drum Window)
    if font_name:lower():match("consolas") or font_name:lower():match("mono") then
        local len = 0
        for _ in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do len = len + 1 end
        return len * fs * Options.dw_char_width
    end
    
    -- Proportional heuristic (standard for OSD)
    local w = 0
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if c == " " then w = w + (fs * 0.30)
        elseif c:match("[il1tI|!.,:;'\"`%(%)%[%]]") then w = w + (fs * 0.22)
        elseif c:match("[mwMW%@]") then w = w + (fs * 0.65)
        elseif c:match("[a-zA-Z0-9]") then w = w + (fs * 0.42)
        elseif #c > 1 then w = w + (fs * 0.45) -- Cyrillic/Wide
        else w = w + (fs * 0.42) end
    end
    return w
end

local function is_inside_dw_selection(l, w)
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    if al == -1 or cl == -1 or aw == -1 or cw == -1 then return false end
    
    local p1_l, p1_w, p2_l, p2_w
    if al < cl or (al == cl and aw <= cw) then
        p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
    else
        p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
    end
    
    if l < p1_l or l > p2_l then return false end
    if l == p1_l and w < p1_w then return false end
    if l == p2_l and w > p2_w then return false end
    return true
end

local function calculate_sub_gap(prefix, font_size, lh_mul, vsp)
    local b_gap_mul = Options[prefix .. "_block_gap_mul"] or 0
    local d_gap = Options[prefix .. "_double_gap"]
    
    if d_gap then
        return (font_size * lh_mul) + (font_size * b_gap_mul) + vsp
    else
        return 0
    end
end

local function calculate_osd_line_meta(text, sub_idx, font_size, font_name, line_height_mul, vsp)
    local tokens = build_word_list_internal(text, Options.dw_original_spacing)
    local space_w = dw_get_str_width(" ", font_size, font_name)
    local words = {}
    local total_w = 0
    
    for j, t in ipairs(tokens) do
        local ww = dw_get_str_width(t.text, font_size, font_name)
        local space = (j > 1 and not Options.dw_original_spacing) and space_w or 0
        
        if t.is_word and t.logical_idx then
            table.insert(words, {
                logical_idx = t.logical_idx,
                x_offset = total_w + space, -- Relative to start of line
                width = ww,
                text = t.text
            })
        end
        total_w = total_w + space + ww
    end
    
    return {
        sub_idx = sub_idx,
        words = words,
        total_width = total_w,
        height = (font_size * line_height_mul) + vsp
    }
end

local function draw_drum(subs, center_idx, y_pos_percent, time_pos, font_size, hit_zones)
    if center_idx == -1 then return "" end
    
    local ass = ""
    local is_drum = (FSM.DRUM == "ON")
    local context_lines = is_drum and Options.drum_context_lines or 0
    local half = context_lines
    local win_lines = 2 * half + 1
    local start_idx = center_idx - half
    local end_idx = center_idx + half

    if start_idx < 1 then
        end_idx = end_idx + (1 - start_idx)
        start_idx = 1
    end
    if end_idx > #subs then
        start_idx = start_idx - (end_idx - #subs)
        end_idx = #subs
    end
    start_idx = math.max(1, start_idx)
    end_idx = math.min(#subs, end_idx)
    local is_top = (y_pos_percent < 50)
    local y_pixel = y_pos_percent * 1080 / 100

    if hit_zones and Options.osd_interactivity then
        local is_drum_mode = (FSM.DRUM == "ON")
        local font_name = is_drum_mode and (Options.drum_font_name ~= "" and Options.drum_font_name or mp.get_property("sub-font", "Inter"))
                                       or (Options.srt_font_name ~= "" and Options.srt_font_name or mp.get_property("sub-font", "Inter"))
        local lh_mul = is_drum_mode and Options.drum_line_height_mul or Options.srt_line_height_mul
        local vsp = is_drum_mode and Options.drum_vsp or Options.srt_vsp
        local prefix = is_drum_mode and "drum" or "srt"
        local d_gap = Options[prefix .. "_double_gap"]
        local b_gap_mul = Options[prefix .. "_block_gap_mul"] or 0

        local line_metas = {}
        for i = start_idx, end_idx do
            local is_active = (i == center_idx)
            local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
            table.insert(line_metas, calculate_osd_line_meta(subs[i].text, i, size, font_name, lh_mul, vsp))
        end
        
        local total_h = 0
        for i, m in ipairs(line_metas) do 
            total_h = total_h + m.height 
            if i < #line_metas then
                local abs_idx = start_idx + i - 1
                local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0
                local line_fs = font_size * ( (abs_idx == center_idx) and Options.drum_active_size_mul or Options.drum_context_size_mul )
                total_h = total_h + calculate_sub_gap(is_drum_mode and "drum" or "srt", line_fs, lh_mul, vsp) + adj
            end
        end
        
        local y_start = y_pixel
        if not is_top then y_start = y_pixel - total_h end
        
        local cur_y = y_start
        for i, m in ipairs(line_metas) do
            m.y_top = cur_y
            m.y_bottom = cur_y + m.height
            m.x_start = 960 - m.total_width / 2
            cur_y = cur_y + m.height
            if i < #line_metas then
                local abs_idx = start_idx + i - 1
                local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0
                local line_fs = font_size * ( (abs_idx == center_idx) and Options.drum_active_size_mul or Options.drum_context_size_mul )
                cur_y = cur_y + calculate_sub_gap(is_drum_mode and "drum" or "srt", line_fs, lh_mul, vsp) + adj
            end
            table.insert(hit_zones, m)
        end
    end
    
    local function format_sub(sub_idx, is_active, t_pos)
        local text = subs[sub_idx] and subs[sub_idx].text or ""
        if text == "" then return "" end
        local is_drum = (FSM.DRUM == "ON")
        
        local base_color = is_drum and (is_active and Options.drum_active_color or Options.drum_context_color)
                                    or (is_active and Options.srt_active_color or Options.srt_context_color)
        local opacity = calculate_ass_alpha(is_drum and (is_active and Options.drum_active_opacity or Options.drum_context_opacity)
                                                     or (is_active and Options.srt_active_opacity or Options.srt_context_opacity))
        
        local font_name = is_drum and (Options.drum_font_name ~= "" and Options.drum_font_name or mp.get_property("sub-font", "Inter"))
                                   or (Options.srt_font_name ~= "" and Options.srt_font_name or mp.get_property("sub-font", "Inter"))
        local f_bold = is_drum and Options.drum_font_bold or Options.srt_font_bold
        local bold_state = (is_active and (is_drum and Options.drum_active_bold or f_bold) 
                                      or (is_drum and Options.drum_context_bold or f_bold)) and "1" or "0"
        
        local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
        
        local tokens = build_word_list_internal(text, Options.dw_original_spacing)
        
        -- Build logical word map to ensure parity with real fractional t.logical_idx
        local visual_to_logical = {}
        for j, t in ipairs(tokens) do
            if t.logical_idx then
                visual_to_logical[j] = t.logical_idx
            end
        end

        -- Level 1 & 2: Base Highlighting (First Pass)
        local token_meta = {}
        for j, t in ipairs(tokens) do
            local l_idx = visual_to_logical[j]
            local meta = { text = t.text, color = base_color, is_word = t.is_word, is_phrase = false, priority = 0 }
            
            -- Level 1: Persistent Selection
            local ctrl_member = l_idx and FSM.DW_CTRL_PENDING_SET[string.format("%d:%g", sub_idx, l_idx)] or nil
            if ctrl_member then
                meta.color = Options.dw_ctrl_select_color
                meta.priority = 1
            end

            -- Level 2: Selection/Hover (Focus Point)
            if meta.priority == 0 and l_idx then
                local is_focus_point = (sub_idx == FSM.DW_CURSOR_LINE and l_idx == FSM.DW_CURSOR_WORD)
                local is_selection = is_inside_dw_selection(sub_idx, l_idx)
                if is_focus_point or is_selection then
                    meta.color = Options.dw_highlight_color
                    meta.priority = 2
                end
            end
            
            -- Level 3: Database Highlights
            if meta.priority == 0 and l_idx then
                local orange_stack, purple_stack, is_phrase = calculate_highlight_stack(subs, sub_idx, j, t_pos)
                local h_color = base_color
                
                if orange_stack > 0 and purple_stack > 0 then
                    local mix_depth = math.min((orange_stack + purple_stack) - 1, 3)
                    if mix_depth == 1 then h_color = Options.anki_mix_depth_1 or "4A4AD3"
                    elseif mix_depth == 2 then h_color = Options.anki_mix_depth_2 or "3636A8"
                    elseif mix_depth >= 3 then h_color = Options.anki_mix_depth_3 or "151578" end
                elseif orange_stack > 0 then
                    if orange_stack == 1 then h_color = Options.anki_highlight_depth_1
                    elseif orange_stack == 2 then h_color = Options.anki_highlight_depth_2
                    elseif orange_stack >= 3 then h_color = Options.anki_highlight_depth_3 end
                elseif purple_stack > 0 then
                    if purple_stack == 1 then h_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
                    elseif purple_stack == 2 then h_color = Options.anki_split_depth_2 or "D97496"
                    elseif purple_stack >= 3 then h_color = Options.anki_split_depth_3 or "B3607C" end
                end

                if h_color ~= base_color then
                    meta.color = h_color
                    meta.is_phrase = is_phrase
                    meta.priority = 3
                end
            end
            token_meta[j] = meta
        end

        -- Pass 2: Semantic Punctuation Coloring
        for j, t in ipairs(tokens) do
            local meta = token_meta[j]
            if meta.priority == 0 and not meta.is_word then
                local prev_meta = token_meta[j-1]
                local next_meta = token_meta[j+1]

                -- Right-sided (Trailing/Internal)
                if prev_meta and prev_meta.priority == 3 and prev_meta.is_phrase then
                    if (next_meta and next_meta.priority == 3 and next_meta.color == prev_meta.color) or (not next_meta or not next_meta.is_word) then
                        meta.color = prev_meta.color
                        meta.is_phrase = true
                    end
                -- Left-sided (Leading)
                elseif next_meta and next_meta.priority == 3 and next_meta.is_phrase then
                    if not prev_meta or not prev_meta.is_word then
                        meta.color = next_meta.color
                        meta.is_phrase = true
                    end
                end
            end
        end

        -- Final Formatting
        local formatted_parts = {}
        for j, t in ipairs(tokens) do
            local meta = token_meta[j]
            if meta.priority == 3 or (meta.priority == 0 and meta.is_phrase) then
                table.insert(formatted_parts, format_highlighted_word({text = meta.text}, meta.color, base_color, meta.is_phrase, bold_state, true))
            elseif meta.priority == 1 or meta.priority == 2 then
                table.insert(formatted_parts, string.format("{\\c&H%s&}%s{\\c&H%s&}", meta.color, meta.text, base_color))
            else
                table.insert(formatted_parts, meta.text)
            end
        end

        local result_text = ""
        if Options.dw_original_spacing then
            result_text = table.concat(formatted_parts, "")
        else
            -- Use unified smart joiner logic for non-raw mode
            result_text = compose_term_smart(formatted_parts)
        end

        return string.format("{\\fn%s}{\\1a&H%s&}{\\b%s}{\\1c&H%s&}{\\fs%d}%s", 
            font_name, opacity, bold_state, base_color, size, result_text)
    end

    local prev_text = {}
    for i = start_idx, center_idx - 1 do
        table.insert(prev_text, format_sub(i, false, subs[i].start_time))
    end
    
    local active_text = ""
    if center_idx > 0 and center_idx <= #subs then
        active_text = format_sub(center_idx, true, subs[center_idx].start_time)
    end
    
    local next_text = {}
    for i = center_idx + 1, end_idx do
        table.insert(next_text, format_sub(i, false, subs[i].start_time))
    end
    
    local is_drum_mode = (FSM.DRUM == "ON")
    local prefix = is_drum_mode and "drum" or "srt"
    local d_gap = Options[prefix .. "_double_gap"]
    local vsp_base = is_drum_mode and Options.drum_vsp or Options.srt_vsp
    local b_gap_mul = Options[prefix .. "_block_gap_mul"] or 0
    local lh_mul = is_drum_mode and Options.drum_line_height_mul or Options.srt_line_height_mul
    local vsp_tag = vsp_base ~= 0 and string.format("{\\vsp%g}", vsp_base) or ""
    
    local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0
    local function get_separator(prev_is_active)
        local line_fs = font_size * (prev_is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
        local vsp_extra = d_gap and (line_fs * b_gap_mul / 2) or 0
        return string.format("{\\vsp%g}%s{\\vsp%g}", vsp_base + vsp_extra + adj, d_gap and "\\N\\N" or "\\N", vsp_base)
    end
    
    local all_text = ""
    for i = start_idx, end_idx do
        local line_text = format_sub(i, i == center_idx, subs[i].start_time)
        if i == start_idx then
            all_text = line_text
        else
            all_text = all_text .. get_separator(i - 1 == center_idx) .. line_text
        end
    end

    local bg_color = is_drum and Options.drum_bg_color or Options.srt_bg_color
    local bg_opacity = is_drum and Options.drum_bg_opacity or Options.srt_bg_opacity
    local bord = is_drum and Options.drum_border_size or Options.srt_border_size
    local shad = is_drum and Options.drum_shadow_offset or Options.srt_shadow_offset
    local style_block = string.format("{\\bord%g}{\\shad%g}{\\4c&H%s&}{\\4a&H%s&}{\\q2}%s", 
        bord, shad, bg_color, calculate_ass_alpha(bg_opacity), vsp_tag)

    if is_top then
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    else
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    end

    return ass
end


-- Unified layout engine: wraps subtitle words into visual lines
local function dw_build_layout(subs, view_center)
    -- Performance Cache Check: Re-use layout if viewport and subs haven't changed.
    -- This drastically reduces CPU load during mouse interaction and OSD updates.
    if FSM.DW_LAYOUT_CACHE and FSM.DW_LAYOUT_CACHE.view_center == view_center and FSM.DW_LAYOUT_CACHE.subs_ptr == subs then
        return FSM.DW_LAYOUT_CACHE.layout, FSM.DW_LAYOUT_CACHE.total_height
    end

    local win_lines = Options.dw_lines_visible
    local half_win = math.floor(win_lines / 2)
    view_center = math.max(1, math.min(#subs, view_center))
    local start_idx = view_center - half_win
    local end_idx = view_center + (win_lines - half_win - 1)

    if start_idx < 1 then
        end_idx = end_idx + (1 - start_idx)
        start_idx = 1
    end
    if end_idx > #subs then
        start_idx = start_idx - (end_idx - #subs)
        end_idx = #subs
    end
    start_idx = math.max(1, start_idx)
    end_idx = math.min(#subs, end_idx)

    local lh_mul = Options.dw_line_height_mul
    local vline_h = (Options.dw_font_size * lh_mul) + Options.dw_vsp
    local sub_gap = calculate_sub_gap("dw", Options.dw_font_size, lh_mul, Options.dw_vsp)
    local max_text_w = 1860
    local space_w = dw_get_str_width(" ")

    local layout = {}
    local total_height = 0

    for i = start_idx, end_idx do
        local text = subs[i].text:gsub("\n", " ")
        local tokens = build_word_list_internal(text, Options.dw_original_spacing)
        if #tokens == 0 then tokens = {""} end

        local logical_words = {}
        local visual_to_logical = {} -- tokens[j] -> index in logical_words
        local logical_to_visual = {} -- logical_words[k] -> index in tokens
        
        for j, t in ipairs(tokens) do
            if t.logical_idx then
                visual_to_logical[j] = t.logical_idx
                logical_to_visual[t.logical_idx] = j
            end
            if is_word_token(t) then
                table.insert(logical_words, t)
            end
        end

        local vlines = {}
        local cur_indices = {}
        local cur_w = 0

        for j, w in ipairs(tokens) do
            local ww = dw_get_str_width(w)
            -- If original spacing is ON, we don't add artificial space width
            local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w or 0
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
            words = tokens, -- Use tokens for visual rendering
            logical_words = logical_words,
            visual_to_logical = visual_to_logical,
            logical_to_visual = logical_to_visual,
            height = entry_h,
            vlines = vlines
        })
        total_height = total_height + entry_h
        if i < end_idx then total_height = total_height + sub_gap end
    end

    -- Store in cache before returning
    FSM.DW_LAYOUT_CACHE = {
        view_center = view_center,
        subs_ptr = subs,
        layout = layout,
        total_height = total_height
    }

    return layout, total_height
end

-- draw_dw: view_center = which line is in the center of the viewport
--          active_idx = which line is currently playing (colored blue, may be off-screen)
local function draw_dw(subs, view_center, active_idx)
    if not subs or #subs == 0 then return "" end
    
    local ass = ""
    local layout, total_height = dw_build_layout(subs, view_center)
    local lh_mul = Options.dw_line_height_mul
    local current_y = 540 - (total_height / 2)
    FSM.DW_LINE_Y_MAP = {}
    
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
    for layout_i, entry in ipairs(layout) do
        local i = entry.sub_idx
        FSM.DW_LINE_Y_MAP[i] = current_y + (entry.height / 2)
        current_y = current_y + entry.height
        if layout_i < #layout then
            local is_active = (entry.sub_idx == active_idx)
            local line_fs = Options.dw_font_size * (is_active and Options.dw_active_size_mul or Options.dw_context_size_mul)
            current_y = current_y + calculate_sub_gap("dw", line_fs, lh_mul, Options.dw_vsp)
        end
        
        local is_active = (i == active_idx)
        local color = is_active and Options.dw_active_color or Options.dw_context_color
        local opacity = calculate_ass_alpha(is_active and Options.dw_active_opacity or Options.dw_context_opacity)
        local font_name = (Options.dw_font_name ~= "") and Options.dw_font_name or mp.get_property("sub-font", "Inter")
        local bold_state = (is_active and Options.dw_active_bold or Options.dw_context_bold) and "1" or "0"
        local f_size = Options.dw_font_size * (is_active and Options.dw_active_size_mul or Options.dw_context_size_mul)
        local line_prefix = string.format("{\\fn%s}{\\fs%d}{\\b%s}{\\c&H%s&}{\\1a&H%s&}", font_name, f_size, bold_state, color, opacity)
        
        local entry_ass_vlines = {}
        for _, vl_indices in ipairs(entry.vlines) do
            local formatted_words = {}

            -- Level 1 & 2: Base Highlighting (First Pass)
            local token_meta = {}
            for _, j in ipairs(vl_indices) do
                local w = entry.words[j]
                local l_idx = entry.visual_to_logical[j]
                local meta = { text = w.text, color = color, is_word = w.is_word, is_phrase = false, priority = 0 }
                
                -- Level 1: Persistent Selection
                local ctrl_member = l_idx and FSM.DW_CTRL_PENDING_SET[string.format("%d:%g", i, l_idx)] or nil
                if ctrl_member then
                    meta.color = Options.dw_ctrl_select_color
                    meta.priority = 1
                end

                -- Level 2: Selection/Hover Focus
                if meta.priority == 0 and l_idx then
                    local selected = false
                    if has_selection then
                        if i > p1_l and i < p2_l then selected = true
                        elseif i == p1_l and i == p2_l then selected = (l_idx >= p1_w and l_idx <= p2_w)
                        elseif i == p1_l then selected = (l_idx >= p1_w)
                        elseif i == p2_l then selected = (l_idx <= p2_w) end
                    end
                    local is_focus_point = (i == cl and l_idx == cw)
                    if selected or is_focus_point then
                        meta.color = Options.dw_highlight_color
                        meta.priority = 2
                    end
                end

                -- Level 3: Database Highlights
                if meta.priority == 0 and l_idx then
                    local orange_stack, purple_stack, is_phrase, matching_terms, purple_depth = calculate_highlight_stack(subs, i, j, subs[i].start_time)
                    meta.purple_depth = purple_depth -- Save for neighbor derivation
                    local h_color = color
                    
                    if orange_stack > 0 and purple_stack > 0 then
                        local mix_depth = math.min((orange_stack + purple_depth) - 1, 3)
                        if mix_depth == 1 then h_color = Options.anki_mix_depth_1 or "4A4AD3"
                        elseif mix_depth == 2 then h_color = Options.anki_mix_depth_2 or "3636A8"
                        elseif mix_depth >= 3 then h_color = Options.anki_mix_depth_3 or "151578" end
                    elseif orange_stack > 0 then
                        if orange_stack == 1 then h_color = Options.anki_highlight_depth_1
                        elseif orange_stack == 2 then h_color = Options.anki_highlight_depth_2
                        elseif orange_stack >= 3 then h_color = Options.anki_highlight_depth_3 end
                    elseif purple_stack > 0 then
                        if purple_depth == 1 then h_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
                        elseif purple_depth == 2 then h_color = Options.anki_split_depth_2 or "D97496"
                        elseif purple_depth >= 3 then h_color = Options.anki_split_depth_3 or "B3607C" end
                    end

                    if h_color ~= color then
                        meta.color = h_color
                        meta.is_phrase = is_phrase
                        meta.matching_terms = matching_terms
                        meta.priority = 3
                    end
                end
                token_meta[j] = meta
            end

            -- Pass 2: Semantic Punctuation Coloring
            for m, j in ipairs(vl_indices) do
                local meta = token_meta[j]
                if meta.priority == 0 and not meta.is_word then
                    local prev_j = vl_indices[m-1]
                    local next_j = vl_indices[m+1]
                    local prev_meta = prev_j and token_meta[prev_j]
                    local next_meta = next_j and token_meta[next_j]

                    -- Right-sided (Trailing/Internal)
                    if prev_meta and prev_meta.priority == 3 and prev_meta.is_phrase then
                        local p_orange = 0
                        local p_purple = 0
                        local p_txt = (prev_meta.text .. meta.text):lower()
                        for _, m_obj in ipairs(prev_meta.matching_terms or {}) do
                            if m_obj.text:lower():find(p_txt, 1, true) then
                                if m_obj.is_split then p_purple = p_purple + 1
                                else p_orange = p_orange + 1 end
                            end
                        end
                        
                        if p_orange > 0 or p_purple > 0 then
                            if (next_meta and next_meta.priority == 3 and next_meta.color == prev_meta.color) or (not next_meta or not next_meta.is_word) then
                                -- Determine specific punctuation color based on ITS OWN stack
                                local p_color = prev_meta.color
                                if p_orange > 0 and p_purple > 0 then
                                    local mix_depth = math.min((p_orange + (prev_meta.purple_depth or 0)) - 1, 3)
                                    if mix_depth == 1 then p_color = Options.anki_mix_depth_1 or "4A4AD3"
                                    elseif mix_depth == 2 then p_color = Options.anki_mix_depth_2 or "3636A8"
                                    elseif mix_depth >= 3 then p_color = Options.anki_mix_depth_3 or "151578" end
                                elseif p_orange > 0 then
                                    local o_depth = math.min(p_orange, 3)
                                    if o_depth == 1 then p_color = Options.anki_highlight_depth_1
                                    elseif o_depth == 2 then p_color = Options.anki_highlight_depth_2
                                    else p_color = Options.anki_highlight_depth_3 end
                                elseif p_purple > 0 then
                                    local p_depth = math.min(prev_meta.purple_depth or 1, 3)
                                    if p_depth == 1 then p_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
                                    elseif p_depth == 2 then p_color = Options.anki_split_depth_2 or "D97496"
                                    else p_color = Options.anki_split_depth_3 or "B3607C" end
                                end

                                meta.color = p_color
                                meta.is_phrase = true
                                meta.matching_terms = prev_meta.matching_terms
                                meta.purple_depth = prev_meta.purple_depth
                            end
                        end
                    -- Left-sided (Leading)
                    elseif next_meta and next_meta.priority == 3 and next_meta.is_phrase then
                        local p_orange = 0
                        local p_purple = 0
                        local n_txt = (meta.text .. next_meta.text):lower()
                        for _, m_obj in ipairs(next_meta.matching_terms or {}) do
                            if m_obj.text:lower():find(n_txt, 1, true) then
                                if m_obj.is_split then p_purple = p_purple + 1
                                else p_orange = p_orange + 1 end
                            end
                        end

                        if p_orange > 0 or p_purple > 0 then
                            if not prev_meta or not prev_meta.is_word then
                                local p_color = next_meta.color
                                if p_orange > 0 and p_purple > 0 then
                                    local mix_depth = math.min((p_orange + (next_meta.purple_depth or 0)) - 1, 3)
                                    if mix_depth == 1 then p_color = Options.anki_mix_depth_1 or "4A4AD3"
                                    elseif mix_depth == 2 then p_color = Options.anki_mix_depth_2 or "3636A8"
                                    elseif mix_depth >= 3 then p_color = Options.anki_mix_depth_3 or "151578" end
                                elseif p_orange > 0 then
                                    local o_depth = math.min(p_orange, 3)
                                    if o_depth == 1 then p_color = Options.anki_highlight_depth_1
                                    elseif o_depth == 2 then p_color = Options.anki_highlight_depth_2
                                    else p_color = Options.anki_highlight_depth_3 end
                                elseif p_purple > 0 then
                                    local p_depth = math.min(next_meta.purple_depth or 1, 3)
                                    if p_depth == 1 then p_color = Options.anki_split_depth_1 or Options.dw_split_select_color or "FF88B0"
                                    elseif p_depth == 2 then p_color = Options.anki_split_depth_2 or "D97496"
                                    else p_color = Options.anki_split_depth_3 or "B3607C" end
                                end

                                meta.color = p_color
                                meta.is_phrase = true
                                meta.matching_terms = next_meta.matching_terms
                                meta.purple_depth = next_meta.purple_depth
                            end
                        end
                    end
                end
            end

            -- Final Formatting
            local formatted_words = {}
            for _, j in ipairs(vl_indices) do
                local meta = token_meta[j]
                if meta.priority == 3 or (meta.priority == 0 and meta.is_phrase) then
                    table.insert(formatted_words, format_highlighted_word({text = meta.text}, meta.color, color, meta.is_phrase, "0", false))
                elseif meta.priority == 1 or meta.priority == 2 then
                    table.insert(formatted_words, string.format("{\\c&H%s&}%s{\\c&H%s&}", meta.color, meta.text, color))
                else
                    table.insert(formatted_words, meta.text)
                end
            end
            local line_ass = ""
            for idx, fw in ipairs(formatted_words) do
                local t_idx = vl_indices[idx]
                local t_raw = entry.words[t_idx]
                local next_v_idx = vl_indices[idx+1]
                local next_t_raw = next_v_idx and entry.words[next_v_idx] or nil
                
                line_ass = line_ass .. fw
                
                if next_t_raw and not Options.dw_original_spacing then
                    -- Smart joiner: No space if current or next word is a hyphen, slash, bracket, or multi-byte dash
                    if t_raw:match("^[/-]$") or t_raw:match("^\226\128\147$") or t_raw:match("^\226\128\148$") or t_raw:match("^[%[%]%(%){}]$") or
                       next_t_raw:match("^[/-]$") or next_t_raw:match("^\226\128\147$") or next_t_raw:match("^\226\128\148$") or next_t_raw:match("^[%[%]%(%){}]$") then
                        -- Join without space
                    else
                        line_ass = line_ass .. " "
                    end
                end
            end
            table.insert(entry_ass_vlines, line_ass)
        end
        -- Join visual lines for this subtitle with ONE \N (soft wrap within the same subtitle)
        table.insert(lines_ass, line_prefix .. table.concat(entry_ass_vlines, "\\N"))
    end
    
    local d_gap = Options.dw_double_gap
    local vsp_base = Options.dw_vsp
    local b_gap_mul = Options.dw_block_gap_mul or 0

    local function get_separator(prev_is_active)
        local line_fs = Options.dw_font_size * (prev_is_active and Options.dw_active_size_mul or Options.dw_context_size_mul)
        local vsp_extra = d_gap and (line_fs * b_gap_mul / 2) or 0
        return string.format("{\\vsp%g}%s{\\vsp%g}", vsp_base + vsp_extra, d_gap and "\\N\\N" or "\\N", vsp_base)
    end

    local block_text = ""
    for i, entry in ipairs(layout) do
        local line_text = lines_ass[i]
        if i == 1 then
            block_text = line_text
        else
            block_text = block_text .. get_separator(layout[i-1].sub_idx == active_idx) .. line_text
        end
    end
    local vsp_tag = Options.dw_vsp ~= 0 and string.format("{\\vsp%g}", Options.dw_vsp) or ""
    -- \q2 disables smart wrapping: forces screen layout to exactly match our dw_build_layout
    ass = ass .. string.format("{\\pos(960, 540)}{\\an5}{\\bord%g}{\\shad%g}{\\4c&H%s&}{\\4a&H%s&}{\\q2}{\\fs%d}%s%s", 
        Options.dw_border_size, Options.dw_shadow_offset, Options.dw_bg_color, calculate_ass_alpha(Options.dw_bg_opacity), Options.dw_font_size, vsp_tag, block_text)
    
    return ass
end

local function draw_dw_tooltip(subs, target_line_idx, osd_y)
    if target_line_idx == -1 or not Tracks.sec.subs or #Tracks.sec.subs == 0 then return "" end
    
    local primary_sub = subs[target_line_idx]
    if not primary_sub then return "" end
    
    local midpoint = (primary_sub.start_time + primary_sub.end_time) / 2
    local center_idx = get_center_index(Tracks.sec.subs, midpoint)
    if center_idx == -1 then return "" end
    
    local start_idx = math.max(1, center_idx - Options.tooltip_context_lines)
    local end_idx = math.min(#Tracks.sec.subs, center_idx + Options.tooltip_context_lines)
    
    local font_name = (Options.tooltip_font_name ~= "") and Options.tooltip_font_name or mp.get_property("sub-font", "Inter")
    local fs = Options.tooltip_font_size
    local line_height = fs * Options.tooltip_line_height_mul
    local bold = Options.tooltip_font_bold and "1" or "0"
    
    local lines_ass = {}
    for i = start_idx, end_idx do
        local is_active = (i == center_idx)
        local color = is_active and Options.tooltip_active_color or Options.tooltip_context_color
        local opacity = is_active and Options.tooltip_active_opacity or Options.tooltip_context_opacity
        local sub_text = Tracks.sec.subs[i].raw_text:gsub("\n", " ")
        
        table.insert(lines_ass, string.format("{\\c&H%s&}{\\1a&H%s&}%s", color, calculate_ass_alpha(opacity), sub_text))
    end
    
    local d_gap = Options.tooltip_double_gap
    local vsp_base = Options.tooltip_vsp
    local b_gap_mul = Options.tooltip_block_gap_mul or 0
    local vsp_extra = d_gap and (fs * b_gap_mul / 2) or 0
    local separator = string.format("{\\vsp%g}%s{\\vsp%g}", vsp_base + vsp_extra, d_gap and "\\N\\N" or "\\N", vsp_base)

    local text_block = table.concat(lines_ass, separator)
    
    local bg_alpha = calculate_ass_alpha(Options.tooltip_bg_opacity)
    local bg_color = Options.tooltip_bg_color
    local bord = Options.tooltip_border_size
    local shad = Options.tooltip_shadow_offset
    
    -- Boundary clamping: Ensure the tooltip doesn't go off-screen
    -- The actual height per logical line includes line_height_mul and vsp
    local num_lines = end_idx - start_idx + 1
    local visual_lines = Options.tooltip_double_gap and (2 * num_lines - 1) or num_lines
    local layout_line_h = (fs * Options.tooltip_line_height_mul) + Options.tooltip_vsp
    
    -- Each logical block has its height, and we use the centralized gap calculation
    -- to ensure parity between visual block_height and hit-testing zones.
    local total_gap = calculate_sub_gap("tooltip", fs, Options.tooltip_line_height_mul, Options.tooltip_vsp)
    local block_height = (num_lines * layout_line_h)
    if num_lines > 1 then
        block_height = block_height + ((num_lines - 1) * total_gap)
    end
    
    local half_h = block_height / 2
    local margin = 20
    local screen_h = 1080 -- Target OSD vertical resolution
    
    -- Apply manual Y offset (unit: logical subtitle intervals)
    -- The interval between the center of Line N and Line N+1
    local logical_interval = layout_line_h + total_gap
    local final_y = osd_y + (Options.tooltip_y_offset_lines * logical_interval)
    
    if final_y - half_h < margin then
        final_y = margin + half_h
    elseif final_y + half_h > screen_h - margin then
        final_y = screen_h - margin - half_h
    end

    -- Single block positioning with \an6 (Right Center) ensures perfect vertical centering on final_y
    local vsp_tag = Options.tooltip_vsp ~= 0 and string.format("{\\vsp%g}", Options.tooltip_vsp) or ""
    -- \q2 ensures parity with hit-testing logic
    local ass = string.format("{\\fn%s}%s{\\pos(1800, %d)}{\\an6}{\\fs%d}{\\b%s}{\\bord%g}{\\shad%g}{\\1c&H%s&}{\\3c&H%s&}{\\4a&H%s&}{\\q2}%s",
        font_name, vsp_tag, final_y, fs, bold, bord, shad, Options.tooltip_active_color, bg_color, bg_alpha, text_block)
        
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
    
    -- ASS text preserves its aspect ratio by scaling isotropically based on window height.
    -- X coordinate scaling must match the Y scaling (oh / 1080) rather than the window width (ow / 1920),
    -- otherwise horizontal click targets drift outwards when the window aspect ratio != 16:9.
    local scale_isotropic = oh / 1080
    local osd_y = my / scale_isotropic
    local osd_x = 960 + ((mx - (ow / 2)) / scale_isotropic)
    
    return osd_x, osd_y
end

local function dw_hit_test(osd_x, osd_y)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return nil, nil end

    local layout, total_height = dw_build_layout(subs, FSM.DW_VIEW_CENTER)

    local vline_h = (Options.dw_font_size * Options.dw_line_height_mul) + Options.dw_vsp
    local sub_gap = (Options.dw_font_size * Options.dw_block_gap_mul)
    if Options.dw_double_gap then
        sub_gap = sub_gap + vline_h
    end
    local space_w = dw_get_str_width(" ")

    local block_top = 540 - total_height / 2

    -- Clamp vertically to the first/last word if outside the entire block
    if osd_y <= block_top then
        local first = layout[1]
        local v_idx = first.vlines[1][1]
        return first.sub_idx, first.visual_to_logical[v_idx] or 1
    end
    if osd_y >= block_top + total_height then
        local last = layout[#layout]
        local last_vl = last.vlines[#last.vlines]
        local v_idx = last_vl[#last_vl]
        return last.sub_idx, last.visual_to_logical[v_idx] or math.max(1, #last.logical_words)
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
                if k < #vl_indices and not Options.dw_original_spacing then 
                    vl_width = vl_width + space_w 
                end
            end
            
            local vl_left = 960 - vl_width / 2

            local cx = osd_x - vl_left
            if cx < 0 then return entry.sub_idx, entry.visual_to_logical[vl_indices[1]] or 1 end
            if cx >= vl_width then return entry.sub_idx, entry.visual_to_logical[vl_indices[#vl_indices]] or math.max(1, #entry.logical_words) end

            -- Build word center positions for snap-to-nearest logic
            local centers = {}
            local pos = 0
            for k, wi in ipairs(vl_indices) do
                local ww = dw_get_str_width(entry.words[wi])
                centers[k] = { idx = wi, center = pos + ww / 2 }
                pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
            end
            -- Find the word whose center is closest to the cursor
            local best_k = 1
            local min_dist = math.abs(cx - centers[1].center)
            for k = 2, #centers do
                local dist = math.abs(cx - centers[k].center)
                if dist < min_dist then
                    min_dist = dist
                    best_k = k
                end
            end
            
            local visual_wi = centers[best_k].idx
            local logical_wi = entry.visual_to_logical[visual_wi]
            
            -- If user clicked on a spacer/filler token, find the nearest selectable word
            if not logical_wi then
                local best_logical = nil
                local best_logic_dist = 999
                for l_idx, v_idx in pairs(entry.logical_to_visual) do
                    local dist = math.abs(v_idx - visual_wi)
                    if dist < best_logic_dist then
                        best_logic_dist = dist
                        best_logical = l_idx
                    end
                end
                logical_wi = best_logical or 1
            end

            return entry.sub_idx, logical_wi
        end
        y_pos = entry_bottom + sub_gap
    end

    -- Fallback safety, should never be reached due to the >= check at the top
    local last = layout[#layout]
    local last_vl = last.vlines[#last.vlines]
    local v_idx = last_vl[#last_vl]
    return last.sub_idx, last.visual_to_logical[v_idx] or math.max(1, #last.logical_words)
end

local function drum_osd_hit_test(osd_x, osd_y)
    if not FSM.DRUM_HIT_ZONES or not Options.osd_interactivity then return nil, nil end
    
    for _, line in ipairs(FSM.DRUM_HIT_ZONES) do
        if osd_y >= line.y_top and osd_y <= line.y_bottom then
            local rel_x = osd_x - line.x_start
            if rel_x >= 0 and rel_x <= line.total_width then
                -- Find closest word in this line
                local best_logical_idx = nil
                local min_dist = math.huge
                for _, word in ipairs(line.words) do
                    local center = word.x_offset + word.width / 2
                    local dist = math.abs(rel_x - center)
                    if dist < min_dist then
                        min_dist = dist
                        best_logical_idx = word.logical_idx
                    end
                end
                return line.sub_idx, best_logical_idx
            end
        end
    end
    return nil, nil
end

local function lls_hit_test_all(osd_x, osd_y)
    if FSM.DRUM_WINDOW ~= "OFF" then
        return dw_hit_test(osd_x, osd_y)
    elseif Options.osd_interactivity then
        return drum_osd_hit_test(osd_x, osd_y)
    end
    return nil, nil
end


local function dw_sync_cursor_to_mouse()
    -- Shield logic: ignore mouse events if a keyboard command or double-click was just triggered
    if mp.get_time() < (FSM.DW_MOUSE_LOCK_UNTIL or 0) then return end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx
    
    if FSM.DRUM_WINDOW ~= "OFF" or Options.osd_interactivity then
        line_idx, word_idx = lls_hit_test_all(osd_x, osd_y)
    end

    if line_idx and word_idx then
        -- Selection & Hover Protection: ONLY update logical cursor if we ARE dragging.
        -- This prevents the active highlight from snapping to the mouse while scrolling
        -- unless the user is consciously selecting something.
        if FSM.DW_MOUSE_DRAGGING and not FSM.DW_PROTECTED_SELECTION then
            FSM.DW_CURSOR_LINE = line_idx
            FSM.DW_CURSOR_WORD = word_idx
        end

        if FSM.DRUM_WINDOW ~= "OFF" then
            local active_idx = get_center_index(subs, mp.get_property_number("time-pos") or 0)
            dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
            dw_osd:update()
        else
            drum_osd:update()
        end
    end

end

local function dw_mouse_update_selection()
    if not FSM.DW_MOUSE_DRAGGING then return end
    dw_sync_cursor_to_mouse()
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
    
    -- ALWAYS update selection to guarantee smooth dragging even if OS drops mouse_move events
    dw_mouse_update_selection()
end

local function cmd_dw_tooltip_pin(tbl)
    if FSM.DRUM_WINDOW == "OFF" then return end
    
    if tbl.event == "down" then
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_HOLDING = true
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end
        
        local osd_x, osd_y = dw_get_mouse_osd()
        local line_idx, _ = dw_hit_test(osd_x, osd_y)
        
        if line_idx then
            FSM.DW_TOOLTIP_LOCKED_LINE = -1
            FSM.DW_TOOLTIP_LINE = line_idx
            local y = FSM.DW_LINE_Y_MAP[line_idx] or osd_y
            local ass = draw_dw_tooltip(subs, line_idx, y)
            dw_tooltip_osd.data = ass
            dw_tooltip_osd:update()
        end
    elseif tbl.event == "up" then
        FSM.DW_TOOLTIP_HOLDING = false
    end
end

local function cmd_toggle_dw_tooltip_hover()
    FSM.DW_TOOLTIP_MODE = (FSM.DW_TOOLTIP_MODE == "CLICK") and "HOVER" or "CLICK"
    show_osd("DW Translation: " .. FSM.DW_TOOLTIP_MODE)
    if FSM.DW_TOOLTIP_MODE == "CLICK" then
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_LINE = -1
        dw_tooltip_osd.data = ""
        dw_tooltip_osd:update()
    end
end

local function cmd_dw_tooltip_toggle()
    if FSM.DRUM_WINDOW == "OFF" then return end
    
    -- If already forced ON, always toggle OFF regardless of current target match
    if FSM.DW_TOOLTIP_FORCE then
        print("[LLS] TOOLTIP TOGGLE: OFF")
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_LINE = -1
        dw_tooltip_osd.data = ""
        dw_tooltip_osd:update()
        return
    end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    -- Determine initial target based on playback/interaction state
    local is_paused = mp.get_property_bool("pause", true)
    local line_idx = -1
    
    if is_paused then
        line_idx = (FSM.DW_TOOLTIP_TARGET_MODE == "CURSOR") and FSM.DW_CURSOR_LINE or FSM.DW_ACTIVE_LINE
        -- Fallback if preferred target is invalid
        if line_idx == -1 then line_idx = FSM.DW_CURSOR_LINE end
    else
        line_idx = FSM.DW_ACTIVE_LINE
    end
    
    if line_idx ~= -1 then
        print("[LLS] TOOLTIP TOGGLE: ON")
        FSM.DW_TOOLTIP_FORCE = true
        FSM.DW_TOOLTIP_LINE = line_idx
        -- Use mapped Y if available, otherwise find it or fallback to a reasonable offset
        local y = FSM.DW_LINE_Y_MAP[line_idx]
        if not y then
            -- Force a redraw or use a midpoint if we're desperate
            y = 540 -- center of 1080p OSD
        end
        dw_tooltip_osd.data = draw_dw_tooltip(subs, line_idx, y)
        dw_tooltip_osd:update()
    end
end

local function dw_tooltip_mouse_update()
    if FSM.DRUM_WINDOW == "OFF" and not Options.osd_interactivity then return end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, _ = lls_hit_test_all(osd_x, osd_y)
    
    -- Keyboard Force takes priority and dynamically targets either the active subtitle or selection cursor based on interaction
    if FSM.DW_TOOLTIP_FORCE then
        local is_paused = mp.get_property_bool("pause", true)
        local target_l
        if not is_paused then
            target_l = FSM.DW_ACTIVE_LINE
        else
            target_l = (FSM.DW_TOOLTIP_TARGET_MODE == "ACTIVE") and FSM.DW_ACTIVE_LINE or FSM.DW_CURSOR_LINE
        end
        
        if target_l ~= -1 then
            FSM.DW_TOOLTIP_LINE = target_l
            local y = FSM.DW_LINE_Y_MAP[target_l]
            if y then
                dw_tooltip_osd.data = draw_dw_tooltip(subs, target_l, y)
                dw_tooltip_osd:update()
            else
                if dw_tooltip_osd.data ~= "" then
                    dw_tooltip_osd.data = ""
                    dw_tooltip_osd:update()
                end
            end
        end
        return
    end
    
    -- Selection-Aware Suppression: Hide tooltip during dragging or if currently locked to this line
    if FSM.DW_MOUSE_DRAGGING or (line_idx and line_idx == FSM.DW_TOOLTIP_LOCKED_LINE) then
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            FSM.DW_TOOLTIP_LINE = -1
            dw_tooltip_osd.data = ""
            dw_tooltip_osd:update()
        end
        return
    end
    
    -- Sticky Suppression Release: Release lock once focus moves to a different line or is lost
    if not FSM.DW_MOUSE_DRAGGING and line_idx ~= FSM.DW_TOOLTIP_LOCKED_LINE then
        FSM.DW_TOOLTIP_LOCKED_LINE = -1
    end

    -- Persistent Range Suppression: If line is in a selection range, it requires manual RMB (similar to CLICK mode)
    local in_selection = false
    if line_idx and FSM.DW_ANCHOR_LINE ~= -1 then
        local start_l = math.min(FSM.DW_CURSOR_LINE, FSM.DW_ANCHOR_LINE)
        local end_l = math.max(FSM.DW_CURSOR_LINE, FSM.DW_ANCHOR_LINE)
        if line_idx >= start_l and line_idx <= end_l then
            in_selection = true
        end
    end

    if (FSM.DW_TOOLTIP_MODE == "HOVER" and not in_selection) or FSM.DW_TOOLTIP_HOLDING then
        local target_l = line_idx
        if target_l and target_l ~= -1 then
            local target_y = FSM.DW_LINE_Y_MAP[target_l]
            if not target_y and FSM.DRUM_WINDOW == "OFF" then
                for _, zone in ipairs(FSM.DRUM_HIT_ZONES or {}) do
                    if zone.sub_idx == target_l then
                        target_y = zone.y_top
                        break
                    end
                end
            end
            if target_y then
                -- Update OSD data on every tick when line is visible to ensure smooth following during scroll
                FSM.DW_TOOLTIP_LINE = target_l
                dw_tooltip_osd.data = draw_dw_tooltip(subs, target_l, target_y)
                dw_tooltip_osd:update()
            else
                if FSM.DW_TOOLTIP_LINE ~= -1 then
                    FSM.DW_TOOLTIP_LINE = -1
                    dw_tooltip_osd.data = ""
                    dw_tooltip_osd:update()
                end
            end
        else
            if FSM.DW_TOOLTIP_LINE ~= -1 then
                FSM.DW_TOOLTIP_LINE = -1
                dw_tooltip_osd.data = ""
                dw_tooltip_osd:update()
            end
        end
    else
        -- CLICK mode or Selection Protected: check if we left the pinned line focus
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            if line_idx ~= FSM.DW_TOOLTIP_LINE then
                FSM.DW_TOOLTIP_LINE = -1
                dw_tooltip_osd.data = ""
                dw_tooltip_osd:update()
            end
        end
    end
end

local function is_abbrev(w)
    if not w then return false end
    
    -- Check user-defined list (case-insensitive)
    local l_word = w:lower()
    local abbrev_list = " " .. (Options.anki_abbrev_list or ""):lower() .. " "
    if abbrev_list:find(" " .. l_word .. " ", 1, true) then
        return true
    end

    if Options.anki_abbrev_smart then
        -- Single or double lowercase letters followed by period: ca. bzw. usw. etc.
        if w:match("^%l+%.$") and #w <= 5 then return true end
        -- Uppercase letter + period patterns: z. (common German prefix)
        if w:match("^%u%.$") then return true end
        -- Two-letter dotted abbreviation: z.B.
        if w:match("^%u%.%u%.$") then return true end
    end
    return false
end

local function dw_anki_export_selection()
    local ok, err = pcall(function()
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end
        
        local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
        local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
        local p1_l, p1_w, p2_l, p2_w = -1, -1, -1, -1
        local term = ""
        local context_line = ""
        local time_pos = 0
        local is_sentence_boundary = false
        local pivot_pos = 0
        local advanced_index = nil

        if al ~= -1 and aw ~= -1 and cl ~= -1 and cw ~= -1 then
            if al < cl or (al == cl and aw <= cw) then
                p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
            else
                p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
            end
            
            if not subs[p1_l] or not subs[p2_l] then return end
            
            local parts = {}
            local term_tokens = {}
            local indices = {}
            local pivot_idx = 1
            for i = p1_l, p2_l do
                local sub = subs[i]
                if sub then
                    local raw_text = sub.text:gsub("\n", " ")
                    local tokens = build_word_list_internal(raw_text, true)
                    local is_first_line = (i == p1_l)
                    local is_last_line = (i == p2_l)
                    
                    local line_parts = {}
                    for _, t in ipairs(tokens) do
                        if t.logical_idx then
                            -- Strict boundary check only applies to the final line where the drag ended
                            if is_last_line and t.logical_idx > p2_w + L_EPSILON then
                                break
                            end

                            -- Include token if it's on a middle/last line OR if it's past the start anchor on the first line
                            if not is_first_line or t.logical_idx >= p1_w - L_EPSILON then
                                table.insert(line_parts, t.text) 
                                table.insert(term_tokens, t.text)
                                if t.is_word then
                                    table.insert(indices, string.format("%d:%g:%d", i - p1_l, t.logical_idx, pivot_idx))
                                    pivot_idx = pivot_idx + 1
                                end
                            end
                        end
                    end
                    
                    if #line_parts > 0 then
                        table.insert(parts, table.concat(line_parts, ""))
                    end
                end
            end
            term = compose_term_smart(term_tokens)
            advanced_index = table.concat(indices, ",")
            
            local ctx_parts = {}
            local char_offset = 0
            pivot_pos = -1
            local start_k = math.max(1, p1_l - Options.anki_context_lines)
            for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines) do
                if subs[k] then 
                    local text = subs[k].text:gsub("{[^}]+}", "")
                    if Options.anki_strip_metadata then text = text:gsub("%b[]", " ") end
                    text = text:gsub("%s+", " ")
                    
                    if k == p1_l then
                        -- Precision Anchor: Find the first word's position in this segment
                        local first_word = parts[1] or ""
                        local s = text:find(first_word, 1, true)
                        if s then
                            pivot_pos = char_offset + s + (#first_word / 2)
                        else
                            pivot_pos = char_offset + (#text / 2)
                        end
                    end
                    
                    table.insert(ctx_parts, text)
                    char_offset = char_offset + #text + 1
                end
            end
            if pivot_pos == -1 then pivot_pos = char_offset / 2 end
            context_line = table.concat(ctx_parts, "\0")
            -- Add small epsilon (1ms) to ensure get_center_index lands inside this segment and not the end of the previous one
            time_pos = subs[p1_l].start_time + 0.001
            print(string.format("[LLS] Export Range: Lines %d-%d, Word Index: %d, Pivot: %.1f", p1_l, p2_l, p1_w, pivot_pos))
            local tokens = get_sub_tokens(subs[p1_l])
            local words = {}
            for _, t in ipairs(tokens) do if t.is_word then table.insert(words, t.text) end end
            print("[LLS] Word List: " .. table.concat(words, " | ", 1, math.min(10, #words)))

            -- Check if selection starts at a boundary
            is_sentence_boundary = (p1_w == 1)
            if not is_sentence_boundary then
                local first_tokens = get_sub_tokens(subs[p1_l])
                local prev_text = nil
                local ptr = 0
                for _, t in ipairs(first_tokens) do
                    if t.is_word then
                        ptr = ptr + 1
                        if ptr == p1_w then break end
                        prev_text = t.text
                    end
                end
                if prev_text and prev_text:match("[.!?]$") and not is_abbrev(prev_text) then
                    is_sentence_boundary = true
                end
            end
        elseif cl ~= -1 and subs[cl] then
            local target_sub = subs[cl]
            local ctx_parts = {}
            local char_offset = 0
            pivot_pos = -1
            
            -- Extract term first so we can use it for pivot anchoring
            if cw ~= -1 then
                local tokens = get_sub_tokens(target_sub)
                local ptr = 0
                local prev_text = nil
                for _, t in ipairs(tokens) do
                    if t.is_word then
                        ptr = ptr + 1
                        if ptr == cw then
                            term = t.text
                            break
                        end
                        prev_text = t.text
                    end
                end
                term = term or target_sub.text
                advanced_index = string.format("0:%g:1", cw)
                -- Check for boundary
                if cw == 1 or (prev_text and prev_text:match("[.!?]$") and not is_abbrev(prev_text)) then
                    is_sentence_boundary = true
                end
            else
                term = target_sub.text
                is_sentence_boundary = true
            end

            local start_k = math.max(1, cl - Options.anki_context_lines)
            for k = start_k, math.min(#subs, cl + Options.anki_context_lines) do
                if subs[k] then 
                    local text = subs[k].text:gsub("{[^}]+}", "")
                    if Options.anki_strip_metadata then text = text:gsub("%b[]", " ") end
                    text = text:gsub("%s+", " ")
                    
                    if k == cl then
                        local word_text = term or ""
                        local s = text:find(word_text, 1, true)
                        if s then
                            pivot_pos = char_offset + s + (#word_text / 2)
                        else
                            pivot_pos = char_offset + (#text / 2)
                        end
                    end
                    
                    table.insert(ctx_parts, text)
                    char_offset = char_offset + #text + 1
                end
            end
            if pivot_pos == -1 then pivot_pos = char_offset / 2 end
            context_line = table.concat(ctx_parts, "\0")
            -- Add small epsilon (1ms) to ensure grounding lands inside this segment
            time_pos = target_sub.start_time + 0.001
            p1_w = cw
            p1_l = cl
            print(string.format("[LLS] Export Point: Line %d, Word Index: %d, Pivot: %.1f", cl, cw, pivot_pos))
            local tokens = get_sub_tokens(target_sub)
            local words = {}
            for _, t in ipairs(tokens) do if t.is_word then table.insert(words, t.text) end end
            print("[LLS] Word List: " .. table.concat(words, " | ", 1, math.min(10, #words)))
        end

        if term and term ~= "" then
            -- Clean term: remove ASS tags and trim whitespace
            term = term:gsub("{[^}]+}", "")
            -- Context-Aware Bracket Stripping:
            -- Remove brackets if and only if they wrap the entire selection.
            -- This preserves brackets inside phrases (e.g. "kann [musik]") 
            -- but strips them for individual metadata picks (e.g. "[musik]" -> "musik").
            if term:match("^%b[]$") then
                term = term:sub(2, -2)
            end
            term = term:gsub("%s+", " "):match("^%s*(.-)%s*$")
            
            -- Clean capture: Remove leading/trailing punctuation (excluding brackets/parentheses)
            local pre = term:match("^[%.%,%!;:%?%-%/\"'»«„“%s]*") or ""
            local suf = term:match("[%.%,%!;:%?%-%/\"'»«„“%s]*$") or ""
            local raw_had_terminal = term:match("[.!?][%s%p]*$") ~= nil
            if #pre < #term then
                term = term:sub(#pre + 1, #term - #suf)
            end
            -- If the selection starts at a boundary AND original subtitle ended with a period (or ! or ?) AND
            -- the cleaned term starts with an uppercase letter AND contains spaces (multi-word), restore the period.
            if is_sentence_boundary and raw_had_terminal and starts_with_uppercase(term) and term:find(" ") and not term:match("[.!?]$") then
                term = term .. "."
            end

            -- Post-cleaning validation: ensure we haven't stripped the term into oblivion
            if not term or term == "" then return end
            
            -- Clean context: remove ASS tags
            context_line = context_line:gsub("{[^}]+}", "")
            if Options.anki_strip_metadata then
                context_line = context_line:gsub("%b[]", " ")
            end
            context_line = context_line:gsub("%s+", " ")
            local term_words = build_word_list(term)
            local effective_limit = math.max(Options.anki_context_max_words, #term_words + 20)
            local extracted_context = extract_anki_context(context_line, term, effective_limit, pivot_pos, advanced_index)
            -- Use the multi-index generated above
            save_anki_tsv_row(term, extracted_context, time_pos, advanced_index)
            show_osd("Anki Highlight Saved: " .. term)

            -- In-memory update was already performed by save_anki_tsv_row.
            -- Removing redundant full-file reload to prevent UI stuttering.
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_WORD = -1
            FSM.DW_CURSOR_X = nil
            
            drum_osd:update()
            if dw_osd then dw_osd:update() end
            if dw_tooltip_osd then dw_tooltip_osd:update() end
        end
    end)
    
    if not ok then
        show_osd("Anki Export Error: " .. tostring(err), 5)
    end
end


local function ctrl_discard_set()
    -- Reset both the persistent pending set (Pink) and any active selection range anchors (Gold)
    FSM.DW_CTRL_PENDING_SET = {}
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() end
end

-- Context-Aware Escape: 3-step cancel then close window
-- Step 1: Clear pink (ctrl pending set) and multi-line yellow selection anchor
-- Step 2: Clear single-word yellow pointer; syncs cursor to active subtitle so
--         the next arrow keypress places the pointer at the first active word
-- Step 3: Close the Drum Window
local function cmd_dw_esc()
    -- Step 1: pink set OR multi-line yellow anchor present → discard both
    if next(FSM.DW_CTRL_PENDING_SET) or FSM.DW_ANCHOR_LINE ~= -1 then
        ctrl_discard_set()
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() 
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end
    -- Step 2: single-word yellow cursor pointer present → hide it
    if FSM.DW_CURSOR_WORD ~= -1 then
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_CURSOR_X = nil
        -- Sync cursor line to the currently active (white) subtitle so that the
        -- next arrow navigation re-materialises the pointer at the right position
        if FSM.DW_ACTIVE_LINE ~= -1 then
            FSM.DW_CURSOR_LINE = FSM.DW_ACTIVE_LINE
        end
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() 
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end
    -- Step 3: nothing left to clear → close the window
    cmd_toggle_drum_window(false)
end

local function get_dw_selection_bounds()
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    
    if al == -1 or aw == -1 or cl == -1 or cw == -1 then return nil end
    if al == cl and aw == cw then return nil end -- Single word is not a "range selection" in this context
    
    if al < cl or (al == cl and aw <= cw) then
        return al, aw, cl, cw
    else
        return cl, cw, al, aw
    end
end

local function ctrl_toggle_word(line_idx, word_idx)
    if line_idx < 1 or word_idx < 0 then return end
    
    local key = string.format("%d:%g", line_idx, word_idx)
    if FSM.DW_CTRL_PENDING_SET[key] then
        FSM.DW_CTRL_PENDING_SET[key] = nil
    else
        FSM.DW_CTRL_PENDING_SET[key] = {line = line_idx, word = word_idx}
    end
    if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() end
end

local function ctrl_commit_set(line_idx, word_idx)
    -- Check if cursor word is in set
    local key = string.format("%d:%g", line_idx, word_idx)
    if not FSM.DW_CTRL_PENDING_SET[key] then
        -- Fallback to plain MMB single-click export
        dw_anki_export_selection()
        return
    end
    
    -- Extract all members into a list and sort by document order
    local members = {}
    for _, m in pairs(FSM.DW_CTRL_PENDING_SET) do
        table.insert(members, m)
    end
    
    if #members == 0 then return end
    
    table.sort(members, function(a, b)
        if a.line ~= b.line then return a.line < b.line end
        return a.word < b.word
    end)
    
    -- Compose the term with adaptive gap detection
    local subs = Tracks.pri.subs
    local term = ""
    local last_m = nil
    
    for _, m in ipairs(members) do
        local sub = subs[m.line]
        if sub then
            local w = nil
            local raw_text = sub.text:gsub("\n", " ")
            local tokens = build_word_list_internal(raw_text, true)
            if tokens then
                for _, t in ipairs(tokens) do
                    if logical_cmp(t.logical_idx, m.word) then
                        w = t.text
                        m.is_word = t.is_word
                        break
                    end
                end
            end
            
            if w then
                local clean_w = w
                if Options.anki_strip_metadata and clean_w:match("^%b[]$") then
                    clean_w = clean_w:gsub("[%[%]]", "")
                end

                if not clean_w:match("^%s*$") then
                    if last_m then
                        local is_gap = false
                        if m.line > last_m.line then
                            local last_line_wc = subs[last_m.line].word_count or 0
                            if (m.line > last_m.line + 1) or (last_m.word < last_line_wc) or (m.word > 1) then
                                is_gap = true
                            end
                        elseif m.word > last_m.word + 1 then
                            is_gap = true
                        end

                        if is_gap then
                            term = term .. " ... "
                        else
                            local interstitial = ""
                            if m.line == last_m.line then
                                for _, t in ipairs(tokens) do
                                    if t.logical_idx > last_m.word and t.logical_idx < m.word then
                                        interstitial = interstitial .. t.text
                                    end
                                end
                            else
                                local trail = ""
                                local last_tokens = build_word_list_internal(subs[last_m.line].text:gsub("\n", " "), true)
                                for _, t in ipairs(last_tokens) do
                                    if t.logical_idx > last_m.word then trail = trail .. t.text end
                                end
                                local lead = ""
                                for _, t in ipairs(tokens) do
                                    if t.logical_idx < m.word then lead = lead .. t.text end
                                end
                                interstitial = trail .. " " .. lead
                            end
                            term = term .. interstitial
                        end
                    end
                    term = term .. clean_w
                    last_m = m
                end
            end
        end
    end
    if term == "" then return end
    
    -- Use the earliest selected word's line for timestamp (document-natural start)
    local time_pos = subs[members[1].line].start_time
    
    -- Gather context lines spanning the full selection (earliest → latest member line),
    -- padded by anki_context_lines on each side.  This ensures the composed term
    -- always appears verbatim inside the context block passed to extract_anki_context.
    local ctx_start = math.max(1, members[1].line - Options.anki_context_lines)
    local ctx_end = math.min(#subs, members[#members].line + Options.anki_context_lines)
    local ctx_parts = {}
    for i = ctx_start, ctx_end do
        table.insert(ctx_parts, subs[i].text)
    end
    local full_ctx_text = table.concat(ctx_parts, " ")
    
    -- Clean context: remove ASS tags and metadata
    full_ctx_text = full_ctx_text:gsub("{[^}]+}", "")
    if Options.anki_strip_metadata then
        full_ctx_text = full_ctx_text:gsub("%b[]", " ")
    end
    full_ctx_text = full_ctx_text:gsub("%s+", " ")

    local term_words = build_word_list(term)
    local effective_limit = math.max(Options.anki_context_max_words, #term_words + 20)
    local pivot_pos = 0
    local current_offset = 0
    for i = ctx_start, ctx_end do
        local line_text = subs[i].text:gsub("{[^}]+}", "")
        if Options.anki_strip_metadata then line_text = line_text:gsub("%b[]", " ") end
        line_text = line_text:gsub("%s+", " ")
        
        if i < members[1].line then
            pivot_pos = pivot_pos + #line_text + 1
        elseif i == members[1].line then
            pivot_pos = pivot_pos + (#line_text / 2)
        end
    end

    local extracted_context = extract_anki_context(full_ctx_text, term, effective_limit, pivot_pos)
    
    -- Advanced Multi-Pivot Grounding: Identify coordinates for ALL words
    local indices = {}
    local start_time = members[1].time or time_pos
    local t_pos_counter = 1
    for _, m in ipairs(members) do
        if m.is_word then
            local l_off = m.line - members[1].line
            table.insert(indices, string.format("%d:%g:%d", l_off, m.word, t_pos_counter))
            t_pos_counter = t_pos_counter + 1
        end
    end
    local advanced_index = table.concat(indices, ",")

    save_anki_tsv_row(term, extracted_context, start_time + 0.001, advanced_index)
    show_osd("Anki Highlight Saved (Multi): " .. term)
    
    -- Force reload of TSV to pick up the new highlight
    load_anki_tsv(true)
    
    -- Clear set
    FSM.DW_CTRL_PENDING_SET = {}
    
    -- Clear selection pointer to immediately show the new highlight color
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    FSM.DW_CURSOR_WORD = -1
    FSM.DW_CURSOR_X = nil
    
    dw_osd:update()
end


local MOUSE_HANDLERS = {}

local function make_mouse_handler(is_shift, on_up_callback, on_down_callback, updates_selection)
    if updates_selection == nil then updates_selection = true end
    local handler = function(tbl)
        -- Shield logic: ignore mouse events if a keyboard command was just triggered
        if mp.get_time() < (FSM.DW_MOUSE_LOCK_UNTIL or 0) then return end
        
        if tbl.event == "down" then
            FSM.DW_FOLLOW_PLAYER = false

            -- Store initial coordinates to detect movement/dragging
            local osd_x, osd_y = dw_get_mouse_osd()
            FSM.DW_MOUSE_DOWN_X, FSM.DW_MOUSE_DOWN_Y = osd_x, osd_y

            -- Dismiss tooltip on click and lock suppression for the current focus
            local line_idx, word_idx = lls_hit_test_all(osd_x, osd_y)
            
            if line_idx then
                FSM.DW_TOOLTIP_LOCKED_LINE = line_idx

                if FSM.DW_TOOLTIP_LINE ~= -1 then
                    FSM.DW_TOOLTIP_LINE = -1
                    dw_tooltip_osd.data = ""
                    dw_tooltip_osd:update()
                end

                -- Phase 1: Custom Actions (Tooltips, Pins, etc.)
                if on_down_callback then on_down_callback(tbl) end

                -- Phase 2: Selection Logic (Only for words, if enabled)
                if word_idx and updates_selection then
                    local is_inside = on_up_callback and is_inside_dw_selection(line_idx, word_idx)
                    FSM.DW_PROTECTED_SELECTION = is_inside and not is_shift
                    
                    -- Standard click (no Shift): reset anchor & cursor unless clicking inside existing range
                    if not is_shift and not is_inside then
                        FSM.DW_ANCHOR_LINE = line_idx
                        FSM.DW_ANCHOR_WORD = word_idx
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    elseif is_shift then
                        if FSM.DW_ANCHOR_LINE == -1 then
                            FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
                            FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
                        end
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    end
                    
                    -- Always start dragging on valid word-click to allow resizing/pulling
                    FSM.DW_MOUSE_DRAGGING = true
                    mp.add_forced_key_binding("mouse_move", "dw-mouse-drag", dw_mouse_update_selection)
                    if FSM.DW_MOUSE_SCROLL_TIMER then FSM.DW_MOUSE_SCROLL_TIMER:kill() end
                    FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(0.05, dw_mouse_auto_scroll)
                    
                    drum_osd:update()
                    if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() end
                end
            end
        elseif tbl.event == "up" then
            FSM.DW_MOUSE_DRAGGING = false
            
            -- POINTER JUMP SYNC: Perform a final hit-test on release ONLY if the mouse 
            -- has moved significantly (dragging). This prevents stationary clicks 
            -- from re-highlighting wrong words when the text shifts vertically 
            -- (e.g. during re-centering or seeking).
            local osd_x, osd_y = dw_get_mouse_osd()
            local dx = math.abs(osd_x - (FSM.DW_MOUSE_DOWN_X or 0))
            local dy = math.abs(osd_y - (FSM.DW_MOUSE_DOWN_Y or 0))
            
            if (dx > 5 or dy > 5) and updates_selection then
                local line_idx, word_idx = lls_hit_test_all(osd_x, osd_y)
                
                if line_idx and word_idx then
                    if not FSM.DW_PROTECTED_SELECTION then
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                    end
                    FSM.DW_TOOLTIP_LOCKED_LINE = line_idx
                end
            end
            
            FSM.DW_PROTECTED_SELECTION = false

            mp.remove_key_binding("dw-mouse-drag")
            if FSM.DW_MOUSE_SCROLL_TIMER then
                FSM.DW_MOUSE_SCROLL_TIMER:kill()
                FSM.DW_MOUSE_SCROLL_TIMER = nil
            end

            if on_up_callback then on_up_callback(tbl) end
        end
    end
    MOUSE_HANDLERS[handler] = true
    return handler
end

local cmd_dw_mouse_select = make_mouse_handler(false)
local cmd_dw_mouse_select_shift = make_mouse_handler(true)

local function dw_anki_export_smart_callback(tbl)
    -- Only trigger on release (Standard export behavior)
    if tbl and tbl.event ~= "up" then return end
    
    local starts_pink = false
    if FSM.DW_ANCHOR_LINE ~= -1 then
        local a_key = string.format("%d:%g", FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD)
        if FSM.DW_CTRL_PENDING_SET[a_key] then starts_pink = true end
    end
    
    if starts_pink then
        ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
    else
        dw_anki_export_selection()
    end
end

local cmd_dw_export_anki = make_mouse_handler(false, dw_anki_export_smart_callback)

local function cmd_dw_add_smart()
    ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
end

local function cmd_dw_toggle_pink(tbl, was_mouse)
    -- Only trigger mouse buttons on release to avoid double-toggle
    if was_mouse and tbl and tbl.event ~= "up" then return end
    
    local line, word
    -- Canonical context check
    local is_mouse = (was_mouse == true)
    
    local p1_l, p1_w, p2_l, p2_w = get_dw_selection_bounds()
    
    if p1_l then
        -- Toggle the entire yellow range into the pink set
        local subs = Tracks.pri.subs
        if not subs then return end
        
        for i = p1_l, p2_l do
            local sub = subs[i]
            if sub then
                local s_w = (i == p1_l) and p1_w or -1
                local e_w = (i == p2_l) and p2_w or 999999
                local in_range = (i > p1_l)
                
                local tokens = get_sub_tokens(sub)
                if tokens then
                    for _, t in ipairs(tokens) do
                        if logical_cmp(t.logical_idx, s_w) then in_range = true end
                        if in_range then
                            if not t.text:match("^%s*$") then
                                ctrl_toggle_word(i, t.logical_idx)
                            end
                        end
                        if logical_cmp(t.logical_idx, e_w) then in_range = false break end
                    end
                end
            end
        end
        -- Clear yellow selection after it "turns pink"
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        -- Only clear drag-binding if we were actually interacting with the mouse
        if is_mouse then
            mp.remove_key_binding("dw-mouse-drag")
        end
        drum_osd:update()
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() end
    else
        -- Fallback to single word toggle (standard behavior)
        if was_mouse then
            local osd_x, osd_y = dw_get_mouse_osd()
            line, word = lls_hit_test_all(osd_x, osd_y)
        else
            line, word = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
        end
        
        if line and line ~= -1 and word and word ~= -1 then
            -- NEVER update cursor/anchor during a toggle-pink action if it was triggered via mouse.
            -- This ensures that RMB (context) or toggle actions don't move the selector.
            ctrl_toggle_word(line, word)
        end
    end
end


local function cmd_dw_double_click()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx = lls_hit_test_all(osd_x, osd_y)
    if not line_idx then return end

    local sub = subs[line_idx]
    if sub and sub.start_time then
        -- Set mouse lock to ignore the trailing "up" event of the double-click
        -- which would otherwise be caught by MBTN_LEFT and trigger a new selection
        -- at the post-seek mouse position.
        FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)

        -- Explicitly terminate any dragging/scrolling state initiated by the first click
        FSM.DW_MOUSE_DRAGGING = false
        mp.remove_key_binding("dw-mouse-drag")
        if FSM.DW_MOUSE_SCROLL_TIMER then
            FSM.DW_MOUSE_SCROLL_TIMER:kill()
            FSM.DW_MOUSE_SCROLL_TIMER = nil
        end

        mp.commandv("seek", sub.start_time, "absolute+exact")
        FSM.DW_CURSOR_LINE = line_idx
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_CURSOR_X = nil
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        
        if not FSM.BOOK_MODE then
            FSM.DW_VIEW_CENTER = line_idx
        end
        
        FSM.DW_FOLLOW_PLAYER = not FSM.BOOK_MODE
        
        -- Explicitly ensure we don't open the full Drum Window (Mode W) 
        -- when interacting in OSD mode (Mode C).
        if FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF" then
            drum_osd:update()
        elseif FSM.DRUM_WINDOW ~= "OFF" then
            dw_osd:update()
        end
    end
end

local function tick_dw(time_pos, active_idx)
    local subs = Tracks.pri.subs
    if #subs == 0 or not active_idx or active_idx == -1 then return end
    
    -- In follow mode: viewport tracks playback; cursor only tracks if no range selection is active
    if FSM.DW_FOLLOW_PLAYER then
        if not FSM.BOOK_MODE then
            if FSM.DW_VIEW_CENTER ~= active_idx then
                FSM.DW_VIEW_CENTER = active_idx
                if FSM.DW_ANCHOR_LINE == -1 then
                    FSM.DW_CURSOR_LINE = active_idx
                    FSM.DW_CURSOR_WORD = -1
                    FSM.DW_CURSOR_X = nil
                end
            end
        elseif not FSM.DW_SEEKING_MANUALLY then
            -- Book Mode: Line-by-line scrolling during playback
            dw_ensure_visible(active_idx, true)
        end
    end
    -- In manual mode: DW_VIEW_CENTER and DW_CURSOR_LINE are frozen,
    -- active_idx just controls the blue highlight color (may be off-screen)
    
    dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
    dw_osd:update()
    
    dw_tooltip_mouse_update()
end

local function tick_drum(time_pos, pri_use_osd, sec_use_osd)
    -- Don't render Drum Mode OSD while Drum Window is open (they overlap)
    if FSM.DRUM_WINDOW ~= "OFF" then return end
    
    local is_drum = (FSM.DRUM == "ON")
    
    -- If no tracks are requested for OSD, clear and return
    if not pri_use_osd and not sec_use_osd then
        if drum_osd.data ~= "" then
            drum_osd.data = ""
            drum_osd:update()
        end
        return
    end

    local ass_text = ""
    local font_size = is_drum 
        and (Options.drum_font_size > 0 and Options.drum_font_size or mp.get_property_number("sub-font-size", 44))
        or (Options.srt_font_size > 0 and Options.srt_font_size or mp.get_property_number("sub-font-size", 44))
    
    local pri_pos = mp.get_property_number("sub-pos", 95)
    local sec_pos = mp.get_property_number("secondary-sub-pos", 10)
    
    local context_lines = is_drum and Options.drum_context_lines or 0
    
    if sec_pos > 50 then
        local max_lines = Options.drum_active_size_mul + (2 * context_lines * Options.drum_context_size_mul)
        local max_pixels = max_lines * font_size * Options.drum_line_height_mul
        -- Calculate safety position (2 blocks above primary + comfort gap)
        local min_safe_pos = pri_pos - (2 * (max_pixels / 1080) * 100) - Options.drum_track_gap
        -- Apply relative offset so user keys (r/t) still work responsively
        local auto_offset = min_safe_pos - Options.sec_pos_bottom
        sec_pos = sec_pos + auto_offset
    end
    
    FSM.DRUM_HIT_ZONES = {}

    -- Draw Primary FIRST, Secondary SECOND (so Secondary is on top in Z-order)
    if pri_use_osd and #Tracks.pri.subs > 0 then
        local idx = get_center_index(Tracks.pri.subs, time_pos)
        ass_text = ass_text .. draw_drum(Tracks.pri.subs, idx, pri_pos, time_pos, font_size, FSM.DRUM_HIT_ZONES)
    end

    if sec_use_osd and #Tracks.sec.subs > 0 then
        local idx = get_center_index(Tracks.sec.subs, time_pos)
        ass_text = ass_text .. draw_drum(Tracks.sec.subs, idx, sec_pos, time_pos, font_size, FSM.DRUM_HIT_ZONES)
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

update_interactive_bindings = function()
    local dw_on = (FSM.DRUM_WINDOW ~= "OFF")
    local osd_on = (FSM.DRUM == "ON" or (not Tracks.pri.is_ass and #Tracks.pri.subs > 0)) and Options.osd_interactivity
    
    local need_mouse = dw_on or osd_on
    local need_kb = dw_on or osd_on
    
    manage_dw_bindings(need_mouse, need_kb)
end

local function master_tick()
    local ok, err = xpcall(function()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    -- Execute Autopause
    if FSM.AUTOPAUSE == "ON" and FSM.SPACEBAR == "IDLE" then
        tick_autopause(time_pos)
    end

    -- Sync active line for Drum/DW logic
    local active_idx = -1
    if #Tracks.pri.subs > 0 then
        active_idx = get_center_index(Tracks.pri.subs, time_pos)
        if active_idx ~= -1 then
            FSM.DW_ACTIVE_LINE = active_idx
        end
    end

    -- Manage native subtitle suppression
    -- We hide native subs if OSD rendering is active OR Drum Window is open.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local dw_active = (FSM.DRUM_WINDOW ~= "OFF")
    
    -- Independent OSD render decisions:
    -- 1. Always use OSD if Drum Mode is ON (Drum Mode auto-disables for ASS anyway)
    -- 2. Use OSD for SRT if configured.
    -- 3. NEVER use OSD for ASS in Regular mode (to preserve styling/layout).
    local pri_use_osd = FSM.native_sub_vis and ((FSM.DRUM == "ON") or (use_osd_for_srt and not Tracks.pri.is_ass))
    local sec_use_osd = FSM.native_sec_sub_vis and ((FSM.DRUM == "ON") or (use_osd_for_srt and not Tracks.sec.is_ass))

    if dw_active or pri_use_osd or sec_use_osd then
        -- Suppression Logic
        -- We hide native if DW is active OR if we are using OSD for that specific track.
        local target_pri_vis = not dw_active and not pri_use_osd and FSM.native_sub_vis
        local target_sec_vis = not dw_active and not sec_use_osd and FSM.native_sec_sub_vis

        if mp.get_property_bool("sub-visibility") ~= target_pri_vis then
            mp.set_property_bool("sub-visibility", target_pri_vis)
        end
        if mp.get_property_bool("secondary-sub-visibility") ~= target_sec_vis then
            mp.set_property_bool("secondary-sub-visibility", target_sec_vis)
        end
        
        -- Only render one-line Drum/SRT OSD if Drum Window is not active
        if not dw_active and (pri_use_osd or sec_use_osd) then
            tick_drum(time_pos, pri_use_osd, sec_use_osd)
        else
            if drum_osd.data ~= "" then
                drum_osd.data = ""
                drum_osd:update()
            end
        end
    else
        -- Clear OSD if not rendering
        if drum_osd.data ~= "" then
            drum_osd.data = ""
            drum_osd:update()
        end
        -- Restore native if user wants subs and we aren't using OSD
        if FSM.native_sub_vis then
            if not mp.get_property_bool("sub-visibility") then
                mp.set_property_bool("sub-visibility", true)
            end
            -- Only restore secondary if it should be on
            if FSM.native_sec_sub_vis and not mp.get_property_bool("secondary-sub-visibility") then
                mp.set_property_bool("secondary-sub-visibility", true)
            elseif not FSM.native_sec_sub_vis and mp.get_property_bool("secondary-sub-visibility") then
                mp.set_property_bool("secondary-sub-visibility", false)
            end
        else
            if mp.get_property_bool("sub-visibility") or mp.get_property_bool("secondary-sub-visibility") then
                mp.set_property_bool("sub-visibility", false)
                mp.set_property_bool("secondary-sub-visibility", false)
            end
        end
    end

    -- Execute Drum Window
    if FSM.DRUM_WINDOW == "DOCKED" then
        tick_dw(time_pos, active_idx)
    elseif Options.osd_interactivity then
        dw_tooltip_mouse_update()
    end
    end, debug.traceback)
    if not ok then
        print("[LLS ERROR] master_tick crash: " .. tostring(err))
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

local function cmd_toggle_anki_global()
    Options.anki_global_highlight = not Options.anki_global_highlight
    show_osd("Anki Global Highlight: " .. (Options.anki_global_highlight and "ON" or "OFF"))
    drum_osd:update()
    if dw_osd then dw_osd:update() end
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
    if not Tracks.pri.path then
        show_osd("Drum Mode: Requires external subtitle files (.srt)")
        return
    end

    if FSM.DRUM == "OFF" then
        FSM.DRUM = "ON"
        -- We no longer update FSM.native_sub_vis here because it's managed by cmd_toggle_sub_vis
        -- and would be overwritten by our own suppression logic.
        
        -- Boot subs for drum memory
        if Tracks.pri.path then Tracks.pri.subs = load_sub(Tracks.pri.path, false) end
        if Tracks.sec.path then Tracks.sec.subs = load_sub(Tracks.sec.path, false) end

        show_osd(string.format("Drum Mode: ON [Double Gap: %s]", Options.drum_double_gap and "YES" or "NO"))
    else
        FSM.DRUM = "OFF"
        show_osd("Drum Mode: OFF")
    end
    update_interactive_bindings()
    -- master_tick handles the sub-visibility property suppression
    drum_osd.data = ""
    drum_osd:update()
end


local function cmd_dw_scroll(dir)
    FSM.DW_FOLLOW_PLAYER = false
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    FSM.DW_VIEW_CENTER = math.max(1, math.min(#subs, FSM.DW_VIEW_CENTER + dir))
    dw_sync_cursor_to_mouse()
end


local function get_first_valid_word_idx(sub)
    if not sub then return -1 end
    local tokens = get_sub_tokens(sub)
    if not tokens then return -1 end
    for _, t in ipairs(tokens) do
        if t.is_word then return t.logical_idx end
    end
    return -1
end

-- Returns the OSD-space x-center of the word with the given logical_idx on sub.
-- Uses the same monospace/proportional width model as dw_hit_test.
-- Returns nil if the word cannot be located.
local function dw_compute_word_center_x(sub)
    -- Returns the OSD x-center of the currently active cursor word (FSM.DW_CURSOR_WORD).
    if not sub or FSM.DW_CURSOR_WORD == -1 then return nil end
    local text = sub.text:gsub("\n", " ")
    local tokens = build_word_list_internal(text, Options.dw_original_spacing)
    local space_w = dw_get_str_width(" ")
    local max_text_w = 1860

    -- Replicate dw_build_layout word-wrap to find which vline contains our word.
    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    for j, w in ipairs(tokens) do
        local ww = dw_get_str_width(w)
        local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w or 0
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

    -- Build visual->logical map.
    local visual_to_logical = {}
    for j, t in ipairs(tokens) do
        if t.logical_idx then visual_to_logical[j] = t.logical_idx end
    end

    -- Scan vlines for the token whose logical_idx matches DW_CURSOR_WORD.
    for _, vl_indices in ipairs(vlines) do
        local vl_width = 0
        for k, wi in ipairs(vl_indices) do
            vl_width = vl_width + dw_get_str_width(tokens[wi])
            if k < #vl_indices and not Options.dw_original_spacing then vl_width = vl_width + space_w end
        end
        local vl_left = 960 - vl_width / 2
        local pos = 0
        for k, wi in ipairs(vl_indices) do
            local ww = dw_get_str_width(tokens[wi])
            if visual_to_logical[wi] == FSM.DW_CURSOR_WORD then
                return vl_left + pos + ww / 2
            end
            pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
        end
    end
    return nil
end

-- Returns the logical word index on sub whose OSD x-center is closest to target_x.
-- Falls back to first word if nothing found.
local function dw_closest_word_at_x(sub, target_x)
    if not sub then return -1 end
    local text = sub.text:gsub("\n", " ")
    local tokens = build_word_list_internal(text, Options.dw_original_spacing)
    local space_w = dw_get_str_width(" ")
    local max_text_w = 1860

    -- Replicate word-wrap.
    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    for j, w in ipairs(tokens) do
        local ww = dw_get_str_width(w)
        local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w or 0
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
    if #vlines == 0 then return get_first_valid_word_idx(sub) end

    local visual_to_logical = {}
    for j, t in ipairs(tokens) do
        if t.logical_idx then visual_to_logical[j] = t.logical_idx end
    end

    local best_logical = nil
    local best_dist = math.huge

    -- For multi-vline subtitles, target_x may sit on any visual row.
    -- We search ALL vlines and pick the globally closest word.
    for _, vl_indices in ipairs(vlines) do
        local vl_width = 0
        for k, wi in ipairs(vl_indices) do
            vl_width = vl_width + dw_get_str_width(tokens[wi])
            if k < #vl_indices and not Options.dw_original_spacing then vl_width = vl_width + space_w end
        end
        local vl_left = 960 - vl_width / 2
        local pos = 0
        for k, wi in ipairs(vl_indices) do
            local ww = dw_get_str_width(tokens[wi])
            local l_idx = visual_to_logical[wi]
            if l_idx and tokens[wi].is_word then
                local cx = vl_left + pos + ww / 2
                local dist = math.abs(cx - target_x)
                if dist < best_dist then
                    best_dist = dist
                    best_logical = l_idx
                end
            end
            pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
        end
    end

    return best_logical or get_first_valid_word_idx(sub)
end


dw_ensure_visible = function(line_idx, paged)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local win_lines = Options.dw_lines_visible
    local half_win = math.floor(win_lines / 2)
    local margin = math.min(Options.dw_scrolloff, math.floor(win_lines / 2) - 1)
    
    -- Calculate current viewport bounds
    local view_min = FSM.DW_VIEW_CENTER - half_win
    local view_max = view_min + win_lines - 1
    
    -- Adjust bounds to account for start/end of file (clamping logic in dw_build_layout)
    if view_min < 1 then
        view_max = view_max + (1 - view_min)
        view_min = 1
    end
    if view_max > #subs then
        view_min = view_min - (view_max - #subs)
        view_max = #subs
    end
    view_min = math.max(1, view_min)
    view_max = math.min(#subs, view_max)

    if paged then
        if line_idx < view_min + margin then
            -- Jump up: active line becomes aligned with bottom margin
            FSM.DW_VIEW_CENTER = math.max(1, line_idx + (win_lines - margin - 1) - half_win)
        elseif line_idx > view_max - margin then
            -- Jump down: active line becomes aligned with top margin
            FSM.DW_VIEW_CENTER = math.min(#subs, line_idx - margin + half_win)
        end
    else
        -- Push (line-by-line)
        if line_idx < view_min + margin then
            local diff = (view_min + margin) - line_idx
            FSM.DW_VIEW_CENTER = math.max(1, FSM.DW_VIEW_CENTER - diff)
        elseif line_idx > view_max - margin then
            local diff = line_idx - (view_max - margin)
            FSM.DW_VIEW_CENTER = math.min(#subs, FSM.DW_VIEW_CENTER + diff)
        end
    end
end


local function cmd_dw_line_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    FSM.DW_FOLLOW_PLAYER = false
    
    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        local start_word = get_first_valid_word_idx(subs[FSM.DW_CURSOR_LINE])
        FSM.DW_ANCHOR_WORD = (FSM.DW_CURSOR_WORD > 0) and FSM.DW_CURSOR_WORD or (start_word > 0 and start_word or 1)
    end

    -- Sticky-X: capture current word's x-center before leaving this line.
    -- If not set yet (fresh cursor), compute from current word; if still nil, use 960 (midpoint).
    if not FSM.DW_CURSOR_X then
        FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE]) or 960
    end
    
    FSM.DW_CURSOR_LINE = math.max(1, math.min(#subs, FSM.DW_CURSOR_LINE + dir))
    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    
    dw_ensure_visible(FSM.DW_CURSOR_LINE, false)
    
    if not shift then
        -- Navigate to the closest word under the sticky horizontal position.
        FSM.DW_CURSOR_WORD = dw_closest_word_at_x(subs[FSM.DW_CURSOR_LINE], FSM.DW_CURSOR_X)
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    else
        if FSM.DW_CURSOR_WORD == -1 then
            FSM.DW_CURSOR_WORD = dw_closest_word_at_x(subs[FSM.DW_CURSOR_LINE], FSM.DW_CURSOR_X)
        end
    end
end

local function cmd_dw_word_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    FSM.DW_FOLLOW_PLAYER = false
    
    -- Capture anchor before moving if shift is held and no anchor exists
    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        if FSM.DW_CURSOR_WORD == -1 then
            local text = subs[FSM.DW_CURSOR_LINE].text:gsub("\n", " ")
            local words = build_word_list(text)
            FSM.DW_ANCHOR_WORD = (dir > 0) and 1 or #words
        else
            FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
        end
    end

    local raw_sub = subs[FSM.DW_CURSOR_LINE]
    if not raw_sub then return end
    local text = raw_sub.text:gsub("\n", " ")
    local words = build_word_list(text)
    
    if FSM.DW_CURSOR_WORD == -1 then
        FSM.DW_CURSOR_WORD = (dir > 0) and 1 or #words
    else
        FSM.DW_CURSOR_WORD = FSM.DW_CURSOR_WORD + dir
    end
    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    
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
    
    FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE])

    if not shift then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    end
end

local function cmd_dw_seek_selected()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    if FSM.DW_CURSOR_LINE > 0 and FSM.DW_CURSOR_LINE <= #subs then
        local sub = subs[FSM.DW_CURSOR_LINE]
        if sub and sub.start_time then
            mp.commandv("seek", sub.start_time, "absolute+exact")
            FSM.DW_FOLLOW_PLAYER = not FSM.BOOK_MODE
            FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
            
            if not FSM.BOOK_MODE then
                FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
            end
            
            show_osd("Seeking to line: " .. FSM.DW_CURSOR_LINE)
        end
    end
end

local function cmd_dw_seek_delta(dir)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end
    
    local current_idx = get_center_index(subs, time_pos)
    if current_idx == -1 then return end
    
    local base_idx = current_idx
    if FSM.DW_SEEKING_MANUALLY and FSM.DW_SEEK_TARGET ~= -1 then
        base_idx = FSM.DW_SEEK_TARGET
    end
    
    local target_idx = math.max(1, math.min(#subs, base_idx + dir))
    FSM.DW_SEEK_TARGET = target_idx
    local sub = subs[target_idx]
    if sub and sub.start_time then
        mp.commandv("seek", sub.start_time, "absolute+exact")
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        
        if FSM.DW_ANCHOR_LINE == -1 then
            if not FSM.BOOK_MODE then
                FSM.DW_CURSOR_LINE = target_idx
                FSM.DW_CURSOR_WORD = -1
                FSM.DW_CURSOR_X = nil
            end
        end
        
        -- Immediate visual feedback for the viewport
        if FSM.BOOK_MODE then
            dw_ensure_visible(target_idx, false)
        else
            FSM.DW_VIEW_CENTER = target_idx
        end
    end
end


local function cmd_seek_with_repeat(dir, table)
    if not table or not table.event then 
        -- Fallback for simple calls if any
        cmd_dw_seek_delta(dir)
        return 
    end

    if table.event == "down" then
        -- Initial press
        FSM.DW_SEEKING_MANUALLY = true
        cmd_dw_seek_delta(dir)
        
        -- Setup repeat timer
        if FSM.SEEK_REPEAT_TIMER then FSM.SEEK_REPEAT_TIMER:kill() end
        FSM.SEEK_REPEAT_TIMER = mp.add_timeout(Options.seek_hold_delay, function()
            FSM.SEEK_REPEAT_TIMER = mp.add_periodic_timer(1.0 / Options.seek_hold_rate, function()
                cmd_dw_seek_delta(dir)
            end)
        end)
    elseif table.event == "up" then
        FSM.DW_SEEKING_MANUALLY = false
        FSM.DW_SEEK_TARGET = -1
        if FSM.SEEK_REPEAT_TIMER then
            FSM.SEEK_REPEAT_TIMER:kill()
            FSM.SEEK_REPEAT_TIMER = nil
        end
    end
end

manage_dw_bindings = function(enable_mouse, enable_kb)
    local function nav(fn, key_name)
        return function(t)
            local key = (t and t.key) or key_name or ""
            if not (key == "Ctrl" or key == "Shift" or key == "Alt" or key == "Meta") then
                FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)
            end
            return fn(t)
        end
    end

    local keys = {}
    
    -- 1. Definitive Keyboard Navigation Group
    local kb_keys = {
        {key = "LEFT", name = "dw-word-left", fn = nav(function() cmd_dw_word_move(-1, false) end, "LEFT")},
        {key = "RIGHT", name = "dw-word-right", fn = nav(function() cmd_dw_word_move(1, false) end, "RIGHT")},
        {key = "UP", name = "dw-line-up", fn = nav(function() cmd_dw_line_move(-1, false) end, "UP")},
        {key = "DOWN", name = "dw-line-down", fn = nav(function() cmd_dw_line_move(1, false) end, "DOWN")},
        {key = "WHEEL_UP", name = "dw-scroll-up", fn = function() cmd_dw_scroll(-1) end},
        {key = "WHEEL_DOWN", name = "dw-scroll-down", fn = function() cmd_dw_scroll(1) end},
        {key = Options.dw_key_pair_mod, name = "dw-pair-mod-track", fn = nav(function(t) 
            FSM.DW_CTRL_HELD = (t.event == "down" or t.event == "repeat")
        end, Options.dw_key_pair_mod), complex = true},
        {key = "ЛЕВЫЙ", name = "dw-word-left-ru", fn = function() cmd_dw_word_move(-1, false) end},
        {key = "ПРАВЫЙ", name = "dw-word-right-ru", fn = function() cmd_dw_word_move(1, false) end},
        {key = "ВВЕРХ", name = "dw-line-up-ru", fn = function() cmd_dw_line_move(-1, false) end},
        {key = "ВНИЗ", name = "dw-line-down-ru", fn = function() cmd_dw_line_move(1, false) end},
    }
    for _, k in ipairs(kb_keys) do 
        k.is_kb = true
        table.insert(keys, k) 
    end

    -- 2. Definitive Mouse Interaction Group
    local mouse_keys = {
        {key = Options.dw_key_select_extend, name = "dw-mouse-select-shift", fn = cmd_dw_mouse_select_shift, complex = true},
        {key = Options.dw_key_mouse_seek, name = "dw-mouse-dblclick", fn = cmd_dw_double_click},
    }
    for _, k in ipairs(mouse_keys) do 
        k.is_mouse = true
        table.insert(keys, k) 
    end

    local function parse_and_collect(key_string, base_name, mouse_fn, key_fn, updates_selection, complex)
        if not key_string or key_string == "" then return end
        local i = 1
        for key in key_string:gmatch("[^%s,;]+") do
            if key ~= "" then
                local is_mouse = key:find("MBTN_") or key:find("WHEEL")
                if is_mouse then
                    local m_fn = (mouse_fn and MOUSE_HANDLERS[mouse_fn]) and mouse_fn or make_mouse_handler(false, 
                        function(t) mouse_fn(t, true) end, 
                        function(t) mouse_fn(t, true) end, 
                        updates_selection
                    )
                    table.insert(keys, { key = key, name = base_name .. "-" .. i, fn = m_fn, complex = true, is_mouse = true })
                else
                    table.insert(keys, { key = key, name = base_name .. "-" .. i, fn = function(t) 
                        local k = (t and t.key) or ""
                        if not (k == "Ctrl" or k == "Shift" or k == "Alt" or k == "Meta") then
                            FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)
                        end
                        key_fn(t, false) 
                    end, complex = complex or false, is_kb = true })
                end
                i = i + 1
            end
        end
    end

    parse_and_collect(Options.dw_key_add, "dw-add", cmd_dw_export_anki, cmd_dw_add_smart, true)
    parse_and_collect(Options.dw_key_pair, "dw-pair", cmd_dw_toggle_pink, cmd_dw_toggle_pink, true)
    parse_and_collect(Options.dw_key_select, "dw-select", cmd_dw_mouse_select, function() end, true)
    parse_and_collect(Options.dw_key_tooltip_pin, "dw-tooltip-pin", cmd_dw_tooltip_pin, cmd_dw_tooltip_pin, false)
    parse_and_collect(Options.dw_key_tooltip_hover, "dw-tooltip-hover", cmd_toggle_dw_tooltip_hover, cmd_toggle_dw_tooltip_hover, false)
    parse_and_collect(Options.dw_key_tooltip_toggle, "dw-tooltip-toggle", cmd_dw_tooltip_toggle, cmd_dw_tooltip_toggle, false)
    parse_and_collect(Options.dw_key_seek_prev, "dw-seek-prev", nil, function(t) cmd_seek_with_repeat(-1, t) end, false, true)
    parse_and_collect(Options.dw_key_seek_next, "dw-seek-next", nil, function(t) cmd_seek_with_repeat(1, t) end, false, true)
    parse_and_collect(Options.dw_key_search, "dw-search", nil, function() cmd_toggle_search() end, false)
    parse_and_collect(Options.dw_key_copy, "dw-copy", nil, function() cmd_dw_copy() end, false)
    parse_and_collect(Options.dw_key_seek, "dw-seek", nil, function() cmd_dw_seek_selected() end, false)
    parse_and_collect(Options.dw_key_esc, "dw-esc", nil, function() cmd_dw_esc() end, false)
    parse_and_collect(Options.dw_key_jump_left, "dw-jump-left", nil, function() cmd_dw_word_move(-Options.dw_jump_words, false) end, false)
    parse_and_collect(Options.dw_key_jump_right, "dw-jump-right", nil, function() cmd_dw_word_move(Options.dw_jump_words, false) end, false)
    parse_and_collect(Options.dw_key_jump_select_left, "dw-jump-select-left", nil, function() cmd_dw_word_move(-Options.dw_jump_words, true) end, false)
    parse_and_collect(Options.dw_key_jump_select_right, "dw-jump-select-right", nil, function() cmd_dw_word_move(Options.dw_jump_words, true) end, false)
    parse_and_collect(Options.dw_key_scroll_up, "dw-scroll-up-ctrl", nil, function() cmd_dw_scroll(-1) end, false)
    parse_and_collect(Options.dw_key_scroll_down, "dw-scroll-down-ctrl", nil, function() cmd_dw_scroll(1) end, false)
    parse_and_collect(Options.dw_key_jump_select_up, "dw-jump-select-up", nil, function() cmd_dw_line_move(-Options.dw_jump_lines, true) end, false)
    parse_and_collect(Options.dw_key_jump_select_down, "dw-jump-select-down", nil, function() cmd_dw_line_move(Options.dw_jump_lines, true) end, false)
    parse_and_collect(Options.dw_key_select_left, "dw-select-left", nil, function() cmd_dw_word_move(-1, true) end, false)
    parse_and_collect(Options.dw_key_select_right, "dw-select-right", nil, function() cmd_dw_word_move(1, true) end, false)
    parse_and_collect(Options.dw_key_select_up, "dw-select-up", nil, function() cmd_dw_line_move(-1, true) end, false)
    parse_and_collect(Options.dw_key_select_down, "dw-select-down", nil, function() cmd_dw_line_move(1, true) end, false)
    parse_and_collect(Options.dw_key_open_record, "dw-open-record", nil, cmd_open_record_file, false)
    parse_and_collect(Options.dw_key_cycle_copy_mode, "dw-cycle-copy-mode", nil, cmd_cycle_copy_mode, false)
    parse_and_collect(Options.dw_key_toggle_copy_context, "dw-toggle-copy-context", nil, cmd_toggle_copy_ctx, false)

    for _, k in ipairs(keys) do
        local active = (k.is_mouse and enable_mouse) or (k.is_kb and enable_kb)
        if active then 
            if k.key and not (k.key == "Ctrl" or k.key == "Shift" or k.key == "Alt" or k.key == "Meta") then
                if k.complex then
                    mp.add_forced_key_binding(k.key, k.name, k.fn, {complex = true})
                else
                    local settings = nil
                    if k.key:match("LEFT") or k.key:match("RIGHT") or k.key:match("UP") or k.key:match("DOWN") 
                       or k.key:match("ЛЕВЫЙ") or k.key:match("ПРАВЫЙ") or k.key:match("ВВЕРХ") or k.key:match("ВНИЗ")
                       or k.key == "ENTER" or k.key == "KP_ENTER" then
                        settings = "repeatable"
                    end
                    mp.add_forced_key_binding(k.key, k.name, k.fn, settings)
                end
            end
        else mp.remove_key_binding(k.name) end
    end

    -- Cleanup Dragging & Window state
    if not enable_mouse then
        FSM.DW_MOUSE_DRAGGING = false
        mp.remove_key_binding("dw-mouse-drag")
        if FSM.DW_MOUSE_SCROLL_TIMER then
            FSM.DW_MOUSE_SCROLL_TIMER:kill()
            FSM.DW_MOUSE_SCROLL_TIMER = nil
        end
        if FSM.DW_NATIVE_WINDOW_DRAGGING ~= nil then
            mp.set_property_bool("window-dragging", FSM.DW_NATIVE_WINDOW_DRAGGING)
        end
        -- Flush tooltip if interaction was lost
        if not enable_kb then
            FSM.DW_TOOLTIP_LINE = -1
            dw_tooltip_osd.data = ""
            dw_tooltip_osd:update()
        end
    else
        if FSM.DW_NATIVE_WINDOW_DRAGGING == nil then
            FSM.DW_NATIVE_WINDOW_DRAGGING = mp.get_property_bool("window-dragging", true)
        end
        mp.set_property_bool("window-dragging", false)
    end
    FSM.DW_KEY_OVERRIDE = enable_kb
end

-- =========================================================================
-- GLOBAL SEARCH FEATURE
-- =========================================================================

local function get_clipboard()
    local platform = package.config:sub(1,1)
    if platform == "\\" then
        local res = utils.subprocess({ args = {"powershell", "-NoProfile", "-Command", "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-Clipboard -Raw"}, cancellable = false })
        if res and res.status == 0 and res.stdout then return res.stdout end
    else
        local un = io.popen("uname -a")
        local uname_str = un and un:read("*a") or ""
        if un then un:close() end
        uname_str = uname_str:lower()
        
        local cmd = ""
        if uname_str:find("darwin") then
            cmd = "pbpaste"
        elseif uname_str:find("android") or (os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux")) then
            cmd = "termux-clipboard-get"
        elseif os.getenv("WAYLAND_DISPLAY") then
            cmd = "wl-paste"
        else
            cmd = "xclip -selection clipboard -o 2>/dev/null || xsel --clipboard --output 2>/dev/null"
        end
        
        if cmd ~= "" then
            local f = io.popen(cmd, "r")
            if f then
                local res = f:read("*a")
                f:close()
                return res
            end
        end
    end
    return ""
end

local function set_clipboard(text)
    local platform = package.config:sub(1,1)
    if platform == "\\" then
        local safe_txt = text:gsub("'", "''")
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value '%s'", safe_txt)
        utils.subprocess({ args = {"powershell", "-NoProfile", "-Command", cmd}, cancellable = false })
    else
        local un = io.popen("uname -a")
        local uname_str = un and un:read("*a") or ""
        if un then un:close() end
        uname_str = uname_str:lower()
        
        local cmd = ""
        if uname_str:find("darwin") then
            cmd = "pbcopy"
        elseif uname_str:find("android") or (os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux")) then
            cmd = "termux-clipboard-set"
        elseif os.getenv("WAYLAND_DISPLAY") then
            cmd = "wl-copy"
        else
            cmd = "xclip -selection clipboard -i 2>/dev/null || xsel --clipboard --input 2>/dev/null"
        end
        
        if cmd ~= "" then
            local f = io.popen(cmd, "w")
            if f then
                f:write(text)
                f:close()
            end
        end
    end
end

local function update_search_results()
    FSM.SEARCH_RESULTS = {}
    FSM.SEARCH_SEL_IDX = 1
    
    if FSM.SEARCH_QUERY == "" then return end
    
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local query = FSM.SEARCH_QUERY
    local scored_results = {}
    
    for i, sub in ipairs(subs) do
        local score, indices = calculate_match_score(sub.text, query)
        if score > 0 then
            table.insert(scored_results, {idx = i, score = score, hl = indices})
        end
    end
    
    -- Sort by score (descending) and then index (ascending)
    table.sort(scored_results, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
        return a.idx < b.idx
    end)
    
    for _, item in ipairs(scored_results) do
        table.insert(FSM.SEARCH_RESULTS, {idx = item.idx, hl = item.hl})
    end
end

local function draw_search_ui()
    if not FSM.SEARCH_MODE then return "" end
    
    local ass = ""
    local padding_x = 20
    local padding_y = 10
    local font_size = Options.search_font_size or Options.dw_font_size
    local font_name = Options.search_font_name ~= "" and Options.search_font_name or Options.dw_font_name
    local line_height = font_size * (Options.search_line_height_mul or 1.2)
    
    -- Positioning Constants (0befa99 layout)
    local box_w = 1200
    local box_x = 960 - (box_w / 2)
    local box_y = 50
    
    local bg_color = Options.search_bg_color or "181818"
    local border_color = "666666"
    local text_color = Options.search_text_color or "FFFFFF"
    local bord = Options.search_border_size or 2.0
    local shad = Options.search_shadow_offset or 0.0
    
    local opacity_hex = calculate_ass_alpha(Options.search_bg_opacity or "60")
    
    -- Draw Input Field Backing
    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\4a&HFF&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
        box_x, box_y, bord, border_color, bg_color, opacity_hex, bg_color, box_w, box_w, line_height + padding_y * 2, line_height + padding_y * 2)
    
    -- Draw Input Text
    local display_query = ""
    local q_table = utf8_to_table(FSM.SEARCH_QUERY)
    
    if #q_table == 0 then
        display_query = "|{\\1a&HAA&}Search...{\\1a&H00&}"
    else
        local cur = FSM.SEARCH_CURSOR
        local anc = FSM.SEARCH_ANCHOR
        local has_sel = (anc ~= -1 and anc ~= cur)
        local s_start = has_sel and math.min(anc, cur) or -1
        local s_end = has_sel and math.max(anc, cur) or -1
        
        for i = 1, #q_table do
            if i == s_start + 1 then
                local q_b = Options.search_query_hit_bold and "{\\b1}" or ""
                display_query = display_query .. string.format("%s{\\1c&H%s&}", q_b, Options.search_query_hit_color)
            end
            
            if i == cur + 1 and not has_sel then
                display_query = display_query .. "|"
            end
            
            display_query = display_query .. q_table[i]
            
            if i == s_end then
                local q_b_end = Options.search_query_hit_bold and "{\\b0}" or ""
                display_query = display_query .. string.format("%s{\\1c&H%s&}", q_b_end, text_color)
            end
        end
        
        -- End-of-line cursor or selection start/end
        if cur == #q_table and not has_sel then
            display_query = display_query .. "|"
        end
    end

    ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad%g}{\\4a&HFF&}{\\fs%d}{\\c&H%s&} %s\n",
        font_name, box_x + padding_x, box_y + padding_y, shad, font_size, "FFFFFF", display_query)
        
    -- Draw Results Dropdown
    if #FSM.SEARCH_RESULTS > 0 then
        local max_results_display = 8
        local display_count = math.min(#FSM.SEARCH_RESULTS, max_results_display)
        local results_h = display_count * line_height + padding_y * 2
        local results_y = box_y + line_height + padding_y * 2 + 5
        
        -- Dropdown Backing
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\4a&HFF&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, bord, border_color, bg_color, opacity_hex, bg_color, box_w, box_w, results_h, results_h)
            
        -- Scroll window mapping
        local start_idx = math.max(1, FSM.SEARCH_SEL_IDX - math.floor(max_results_display / 2))
        if start_idx + max_results_display - 1 > #FSM.SEARCH_RESULTS then
            start_idx = math.max(1, #FSM.SEARCH_RESULTS - max_results_display + 1)
        end
        
        for k = 1, display_count do
            local result_idx = start_idx + k - 1
            if result_idx > #FSM.SEARCH_RESULTS then break end
            
            local result_data = FSM.SEARCH_RESULTS[result_idx]
            local sub_line_idx = result_data.idx
            local sub_text = Tracks.pri.subs[sub_line_idx].text:gsub("\n", " ")
            local raw_t_table = utf8_to_table(sub_text)
            
            -- Truncate for display
            if #raw_t_table > 120 then 
                local new_t = {}
                for i = 1, 120 do table.insert(new_t, raw_t_table[i]) end
                sub_text = table.concat(new_t) .. "..."
                raw_t_table = utf8_to_table(sub_text)
            end
            
            local item_y = results_y + padding_y + (k - 1) * line_height
            local is_selected = (result_idx == FSM.SEARCH_SEL_IDX)
            local base_color = is_selected and Options.search_sel_color or text_color
            local sel_bold = (is_selected and Options.search_sel_bold) and "{\\b1}" or ""
            local sel_bold_end = (is_selected and Options.search_sel_bold) and "{\\b0}" or ""
            
            -- Construct highlighted string
            local display_text = ""
            local hit_color = is_selected and (Options.search_query_hit_color or "FFFFFF") or Options.search_hit_color
            local hit_bold = Options.search_hit_bold and "{\\b1}" or ""
            local hit_bold_end = Options.search_hit_bold and "{\\b0}" or ""
            
            for i = 1, #raw_t_table do
                local is_hit = result_data.hl and result_data.hl[i]
                if is_hit then
                    display_text = display_text .. string.format("%s{\\c&H%s&}%s%s{\\c&H%s&}", hit_bold, hit_color, raw_t_table[i], hit_bold_end, base_color)
                else
                    display_text = display_text .. raw_t_table[i]
                end
            end
            
            local r_font_size = font_size
            if Options.search_results_font_size then
                if Options.search_results_font_size > 0 then
                    r_font_size = Options.search_results_font_size
                elseif Options.search_results_font_size == -1 then
                    r_font_size = font_size * 0.8
                end
            end
            ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&HFF&}{\\fs%d}{\\c&H%s&} %s%s%s\n",
                font_name, box_x + padding_x, item_y, r_font_size, base_color, sel_bold, display_text, sel_bold_end)
        end
    elseif FSM.SEARCH_QUERY ~= "" then
        -- "No results"
        local results_h = line_height + padding_y * 2
        local results_y = box_y + line_height + padding_y * 2 + 5
        
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\4a&HFF&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, bord, border_color, bg_color, opacity_hex, bg_color, box_w, box_w, results_h, results_h)
            
        local r_font_size = font_size
        if Options.search_results_font_size then
            if Options.search_results_font_size > 0 then
                r_font_size = Options.search_results_font_size
            elseif Options.search_results_font_size == -1 then
                r_font_size = font_size * 0.8
            end
        end
        ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&HFF&}{\\fs%d}{\\c&H%s&} No results found.\n",
            font_name, box_x + padding_x, results_y + padding_y, r_font_size, "999999")
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

local function manage_ui_border_override(enable)
    -- Deprecated: We now rely on \4a&HFF& in ASS to hide background box.
    -- Kept to avoid breaking existing bindings/calls.
end

local function manage_search_bindings(enable)
    local function bind(key_string, name, fn, settings)
        if not key_string then return end
        local i = 1
        for key in key_string:gmatch("[^%s,;]+") do
            mp.add_forced_key_binding(key, "search-" .. name .. "-" .. i, fn, settings)
            i = i + 1
        end
    end

    local function unbind(key_string, name)
        if not key_string then return end
        local i = 1
        for key in key_string:gmatch("[^%s,;]+") do
            mp.remove_key_binding("search-" .. name .. "-" .. i)
            i = i + 1
        end
    end

    if enable then
        FSM.SEARCH_MODE = true
        FSM.SEARCH_QUERY = ""
        FSM.SEARCH_RESULTS = {}
        FSM.SEARCH_SEL_IDX = 1
        FSM.SEARCH_CURSOR = 0
        FSM.SEARCH_ANCHOR = -1
        
        manage_ui_border_override(true)
        
        -- Boot subs for memory if haven't already
        if Tracks.pri.path and #Tracks.pri.subs == 0 then
            Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
        end
        
        -- Temporarily clear main DW bindings that conflict with typing if Drum Window is open
        if FSM.DRUM_WINDOW == "DOCKED" then
            manage_dw_bindings(false)
        end
        
        local chars = "abcdefghijklmnopqrstuvwxyz1234567890-=[]\\;',./ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+{}|:\"<>?абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯäöüßÄÖÜẞ "
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
        bind(Options.search_key_bs, "bs", function()
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
        
        bind(Options.search_key_del, "del", function()
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
        
        -- Hardcoded Search Keys (documented only)
        mp.add_forced_key_binding("LEFT", "search-left", function() move_search_cursor(-1, false, false) end, "repeatable")
        mp.add_forced_key_binding("RIGHT", "search-right", function() move_search_cursor(1, false, false) end, "repeatable")
        
        bind(Options.search_key_select_left, "left-shift", function() move_search_cursor(-1, false, true) end, "repeatable")
        bind(Options.search_key_select_right, "right-shift", function() move_search_cursor(1, false, true) end, "repeatable")
        bind(Options.search_key_jump_left, "left-ctrl", function() move_search_cursor(-1, true, false) end, "repeatable")
        bind(Options.search_key_jump_right, "right-ctrl", function() move_search_cursor(1, true, false) end, "repeatable")
        bind(Options.search_key_jump_select_left or "Ctrl+Shift+LEFT", "left-ctrl-shift", function() move_search_cursor(-1, true, true) end, "repeatable")
        bind(Options.search_key_jump_select_right or "Ctrl+Shift+RIGHT", "right-ctrl-shift", function() move_search_cursor(1, true, true) end, "repeatable")

        bind(Options.search_key_home, "home", function()
            FSM.SEARCH_CURSOR = 0
            FSM.SEARCH_ANCHOR = -1
            render_search()
        end)
        bind(Options.search_key_end, "end", function()
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
        
        bind(Options.search_key_enter, "enter", function()
            if #FSM.SEARCH_RESULTS > 0 then
                local selected_line = FSM.SEARCH_RESULTS[FSM.SEARCH_SEL_IDX].idx
                local sub = Tracks.pri.subs[selected_line]
                
                if sub.start_time then
                    mp.commandv("seek", sub.start_time, "absolute+exact")
                    FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
                end
                
                -- Update DW state so if it opens, or is open, it jumps to this line
                FSM.DW_CURSOR_LINE = selected_line
                FSM.DW_CURSOR_WORD = -1
                FSM.DW_CURSOR_X = nil
                FSM.DW_VIEW_CENTER = selected_line
                FSM.DW_FOLLOW_PLAYER = true
                FSM.DW_ANCHOR_LINE = -1
                FSM.DW_ANCHOR_WORD = -1
                
                cmd_toggle_search()
            end
        end)
        
        bind(Options.search_key_esc, "esc", function()
            cmd_toggle_search()
        end)

        mp.add_forced_key_binding("WHEEL_UP", "search-wheel-up", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.max(1, FSM.SEARCH_SEL_IDX - 1)
                render_search()
            end
        end)
        mp.add_forced_key_binding("WHEEL_DOWN", "search-wheel-down", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.min(#FSM.SEARCH_RESULTS, FSM.SEARCH_SEL_IDX + 1)
                render_search()
            end
        end)
        
        local function paste_from_clipboard()
            local clipboard_txt = get_clipboard()
            if clipboard_txt and clipboard_txt ~= "" then
                local txt = clipboard_txt:gsub("\r", ""):gsub("\n", " ")
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
        bind(Options.search_key_paste, "paste", paste_from_clipboard, "repeatable")
        
        local function select_all()
            FSM.SEARCH_ANCHOR = 0
            FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
            render_search()
        end
        bind(Options.search_key_select_all, "select-all", select_all)
        
        local function delete_word_before_cursor()
            if FSM.SEARCH_QUERY == "" or FSM.SEARCH_CURSOR == 0 then return end
            
            local q_table = utf8_to_table(FSM.SEARCH_QUERY)
            local target_pos = get_word_boundary(q_table, FSM.SEARCH_CURSOR, -1)
            
            -- If we have a selection, delete it first (standard behavior)
            if FSM.SEARCH_ANCHOR ~= -1 and FSM.SEARCH_ANCHOR ~= FSM.SEARCH_CURSOR then
                local s_start = math.min(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                local s_end = math.max(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                for i = s_end, s_start + 1, -1 do
                    table.remove(q_table, i)
                end
                FSM.SEARCH_CURSOR = s_start
                FSM.SEARCH_ANCHOR = -1
            else
                -- Delete range from target_pos up to SEARCH_CURSOR
                for i = FSM.SEARCH_CURSOR, target_pos + 1, -1 do
                    table.remove(q_table, i)
                end
                FSM.SEARCH_CURSOR = target_pos
            end
            
            FSM.SEARCH_QUERY = table.concat(q_table)
            update_search_results()
            render_search()
        end
        bind(Options.search_key_delete_word, "delete-word", delete_word_before_cursor, "repeatable")
        
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
                                local selected_line = FSM.SEARCH_RESULTS[FSM.SEARCH_SEL_IDX].idx
                                local sub = Tracks.pri.subs[selected_line]
                                
                                if sub.start_time then
                                    mp.commandv("seek", sub.start_time, "absolute+exact")
                                    FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
                                end
                                
                                FSM.DW_CURSOR_LINE = selected_line
                                FSM.DW_CURSOR_WORD = -1
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
        bind(Options.search_key_click, "mouse-click", search_mouse_click, {complex = true})
        
        render_search()
    else
        FSM.SEARCH_MODE = false
        manage_ui_border_override(false)
        
        local chars = "abcdefghijklmnopqrstuvwxyz1234567890-=[]\\;',./ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+{}|:\"<>?абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ "
        local function utf8_iter(str)
            return string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*")
        end
        for ch in utf8_iter(chars) do
            local key_name = ch
            if ch == " " then key_name = "SPACE" end
            mp.remove_key_binding("search-char-" .. key_name)
        end
        
        unbind(Options.search_key_bs, "bs")
        unbind(Options.search_key_del, "del")
        mp.remove_key_binding("search-left")
        mp.remove_key_binding("search-right")
        unbind(Options.search_key_select_left, "left-shift")
        unbind(Options.search_key_select_right, "right-shift")
        unbind(Options.search_key_jump_left, "left-ctrl")
        unbind(Options.search_key_jump_right, "right-ctrl")
        unbind(Options.search_key_jump_select_left or "Ctrl+Shift+LEFT", "left-ctrl-shift")
        unbind(Options.search_key_jump_select_right or "Ctrl+Shift+RIGHT", "right-ctrl-shift")
        unbind(Options.search_key_home, "home")
        unbind(Options.search_key_end, "end")
        mp.remove_key_binding("search-up")
        mp.remove_key_binding("search-down")
        unbind(Options.search_key_enter, "enter")
        unbind(Options.search_key_esc, "esc")
        mp.remove_key_binding("search-wheel-up")
        mp.remove_key_binding("search-wheel-down")
        unbind(Options.search_key_paste, "paste")
        unbind(Options.search_key_select_all, "select-all")
        unbind(Options.search_key_delete_word, "delete-word")
        unbind(Options.search_key_click, "mouse-click")
        
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
        if not Tracks.pri.path and not Tracks.sec.path then
            show_osd("Search: Requires external subtitle files")
            return
        end
        manage_search_bindings(true)
    else
        manage_search_bindings(false)
    end
end

function cmd_toggle_drum_window()
    print("[LLS] TOGGLE CALLED: FSM.DRUM_WINDOW=" .. tostring(FSM.DRUM_WINDOW))
    -- Snapshot FSM state before any mutation so we can roll back on error
    local prev_drum_window = FSM.DRUM_WINDOW
    local ok, err = xpcall(function()
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Drum Window: No subtitles loaded")
        return
    end
    -- Support both external (path-based) and internal (loaded into memory) tracks.
    -- If no subs are in memory and no path exists, we truly can't open.
    if not Tracks.pri.path and #Tracks.pri.subs == 0 then
        show_osd("Drum Window: requires loaded subtitles")
        return
    end


    if FSM.DRUM_WINDOW == "OFF" then
        print("[LLS] OPENING DRUM WINDOW...")
        -- Update state immediately for responsiveness
        FSM.DRUM_WINDOW = "DOCKED"
        manage_ui_border_override(true)

        -- Refresh TSV before opening: catches any mid-session file deletion or clearing.
        load_anki_tsv(true)

        -- Snapshot and hide all subtitle overlays to prevent overlap
        FSM.DW_SAVED_SUB_VIS = FSM.native_sub_vis
        FSM.DW_SAVED_DRUM_STATE = FSM.DRUM

        -- Hide native subs (for compatibility and to ensure they are off)
        mp.set_property_bool("sub-visibility", false)
        mp.set_property_bool("secondary-sub-visibility", false)
        
        -- Always hide drum_osd, as it now renders both Drum and Regular SRT modes
        drum_osd.data = ""
        drum_osd:update()

        local time_pos = mp.get_property_number("time-pos")
        if FSM.DW_CURSOR_LINE == -1 then
            FSM.DW_CURSOR_LINE = get_center_index(Tracks.pri.subs, time_pos)
            FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
        end
        FSM.DW_SEEKING_MANUALLY = false
        FSM.DW_SEEK_TARGET = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_FOLLOW_PLAYER = true
        
        if not FSM.SEARCH_MODE then
            update_interactive_bindings()
        end

        -- Explicitly trigger first render for instant appearance
        if FSM.DRUM_WINDOW == "DOCKED" then
            local active_idx = get_center_index(Tracks.pri.subs, time_pos or 0)
            tick_dw(time_pos or 0, active_idx)
            show_osd(string.format("Drum Window: ON [Double Gap: %s]", Options.dw_double_gap and "YES" or "NO"))
        end
    else
        print("[LLS] CLOSING DRUM WINDOW...")
        -- Update state immediately
        FSM.DRUM_WINDOW = "OFF"
        FSM.DW_TOOLTIP_FORCE = false
        dw_tooltip_osd.data = ""
        dw_tooltip_osd:update()
        manage_ui_border_override(false)

        if not FSM.SEARCH_MODE then
            update_interactive_bindings()
        end
        dw_osd.data = ""
        dw_osd:update()

        -- Restore subtitle visibility
        FSM.native_sub_vis = FSM.DW_SAVED_SUB_VIS
    end
    end, debug.traceback)
    if not ok then
        -- Roll back FSM state to prevent phantom window open/close on next toggle
        FSM.DRUM_WINDOW = prev_drum_window
        print("[LLS ERROR] Drum Window Toggle: " .. tostring(err))
        show_osd("LLS ERROR: " .. tostring(err):sub(1, 100))
    end

end

function toggle_book_mode()
    FSM.BOOK_MODE = not FSM.BOOK_MODE
    if FSM.BOOK_MODE then
        if FSM.DRUM_WINDOW == "OFF" then
            cmd_toggle_drum_window()
        end
        show_osd("Book Mode: ON")
    else
        show_osd("Book Mode: OFF")
    end
end




function cmd_dw_copy()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local cl = FSM.DW_CURSOR_LINE
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cw = FSM.DW_CURSOR_WORD

    -- 0. Smart Focus Fallback for Book Mode
    -- In Book Mode, if we are in 'Follow' mode (e.g. navigation via a/d),
    -- prefer the active playback line if no specific word/range is selected.
    if FSM.BOOK_MODE and FSM.DW_FOLLOW_PLAYER and al == -1 and cw == -1 then
        cl = FSM.DW_ACTIVE_LINE
    end
    -- Fallback for Esc state or between-subs
    if cl == -1 then cl = FSM.DW_ACTIVE_LINE end
    if cl == -1 then return end

    local final_text = ""
    local selection_text = ""
    local is_context = false
    
    -- 1. Calculate Selection/Line Text (Required for verbatim fallback and context wrapping)
    if al ~= -1 and aw ~= -1 and cl ~= -1 and cw ~= -1 then
        -- Range selection (always verbatim from primary track for precision)
        local p1_l, p1_w, p2_l, p2_w
        if al < cl or (al == cl and aw <= cw) then
            p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
        else
            p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
        end
        
        local parts = {}
        for i = p1_l, p2_l do
            local text = subs[i].text:gsub("\n", " ")
            local tokens = build_word_list_internal(text, true)
            
            local s_w = (i == p1_l) and p1_w or 1
            local e_w = (i == p2_l) and p2_w or nil
            
            if not e_w then
                local wc = 0
                for _, t in ipairs(tokens) do if t.is_word then wc = wc + 1 end end
                e_w = wc
            end
            
            local line_parts = {}
            local in_range = false
            for _, t in ipairs(tokens) do
                if logical_cmp(t.logical_idx, s_w) then in_range = true end
                if in_range then table.insert(line_parts, t.text) end
                if logical_cmp(t.logical_idx, e_w) then in_range = false break end
            end
            
            if #line_parts > 0 then
                table.insert(parts, table.concat(line_parts, ""))
            end
        end
        selection_text = table.concat(parts, " ")
    else
        -- Single point or line fallback (Respects COPY_MODE B for translations)
        local target_subs = subs
        if FSM.COPY_MODE == "B" and Tracks.sec.subs and #Tracks.sec.subs >= cl then
            target_subs = Tracks.sec.subs
        end
        
        local text = target_subs[cl].text:gsub("\n", " ")
        if FSM.DW_CURSOR_WORD > 0 and FSM.COPY_MODE == "A" then
            local words = build_word_list(text)
            selection_text = words[FSM.DW_CURSOR_WORD] or text
        else
            selection_text = text
        end
    end

    -- 2. Check for Context Copy (Matches cmd_copy_sub behavior)
    if FSM.COPY_CONTEXT == "ON" then
        local ctx = get_copy_context_text(nil, cl)
        if ctx and ctx ~= "" then
            -- Requirement: Verbatim Selection with Context
            -- If we have a specific selection (word or range), replace the focal line in the context.
            -- We clean the context of ASS tags FIRST to ensure gsub matching works against the focal line.
            ctx = ctx:gsub("{[^}]+}", "")
            
            local target_line = subs[cl].text:gsub("\n", " "):gsub("{[^}]+}", ""):match("^%s*(.-)%s*$") or ""
            local esc_target = target_line:gsub("[%[%]%(%)%.%+%-%*%?%^%$%%]", "%%%1")
            local clean_sel = selection_text:gsub("{[^}]+}", ""):match("^%s*(.-)%s*$") or ""
            
            if esc_target ~= "" and esc_target ~= clean_sel then
                ctx = ctx:gsub(esc_target, clean_sel)
            end
            
            final_text = ctx:gsub("\n", " ")
            is_context = true
        end
    end

    -- 3. Final Fallback
    if final_text == "" then
        final_text = selection_text
    end
    
    if final_text ~= "" then
        -- Remove ASS tags but keep all punctuation and formatting (Requirement: Copy as is)
        final_text = final_text:gsub("{[^}]+}", "")
        
        set_clipboard(final_text)
        local label = is_context and "Context" or "DW"
        show_osd(label .. " Copied: " .. final_text:sub(1, 40) .. (#final_text > 40 and "..." or ""))
    end
end

local function cmd_toggle_sub_vis()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("Subtitles: Managed by Drum Window")
        return
    end
    local nxt = not FSM.native_sub_vis
    FSM.native_sub_vis = nxt
    FSM.native_sec_sub_vis = nxt
    
    -- We don't set mpv's sub-visibility to 'true' here because master_tick 
    -- would immediately set it back to 'false' to render our styled OSD.
    -- If user wants to DISABLE subs, we set it to false for safety.
    if not nxt then
        mp.set_property_bool("sub-visibility", false)
        mp.set_property_bool("secondary-sub-visibility", false)
    end
    
    show_osd("Subtitles: " .. (nxt and string.format("ON [Double Gap: %s]", Options.srt_double_gap and "YES" or "NO") or "OFF"))
    master_tick()
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
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
        show_osd("Secondary Sub Pos: " .. ((FSM.native_sec_sub_pos < 50) and "TOP" or "BOTTOM"))
    else
        local p = mp.get_property_number("secondary-sub-pos", Options.sec_pos_top)
        local n = (p < 50) and Options.sec_pos_bottom or Options.sec_pos_top
        mp.set_property_number("secondary-sub-pos", n)
        show_osd("Secondary Sub Pos: " .. ((n < 50) and "TOP" or "BOTTOM"))
    end
end

local function cmd_adjust_sub_pos(delta)
    local p = mp.get_property_number("sub-pos", 95)
    mp.set_property_number("sub-pos", math.max(0, math.min(150, p + delta)))
end

local function cmd_adjust_sec_sub_pos(delta)
    local p = mp.get_property_number("secondary-sub-pos", 10)
    mp.set_property_number("secondary-sub-pos", math.max(0, math.min(150, p + delta)))
end

local function cmd_cycle_sec_sid()
    if FSM.DRUM == "ON" then FSM.native_sec_sub_vis = true
    else mp.set_property_bool("secondary-sub-visibility", true) end

    mp.command("no-osd cycle secondary-sid")
    local ssid = mp.get_property_number("secondary-sid", 0)
    if ssid == 0 then
        -- Before just saying "OFF", check if there's actually anything to cycle to
        local tracks = mp.get_property_native("track-list") or {}
        local sub_count = 0
        local is_ass = false
        for _, t in ipairs(tracks) do
            if t.type == "sub" then
                sub_count = sub_count + 1
                if t.codec == "ass" or t.codec == "ssa" or (t["external-filename"] and (t["external-filename"]:lower():match("%.ass$") or t["external-filename"]:lower():match("%.ssa$"))) then
                    is_ass = true
                end
            end
        end

        if sub_count <= 1 then
            if is_ass then
                show_osd("Secondary Subtitles: Managed internally by ASS styling")
            else
                show_osd("Secondary Subtitles: Only 1 track available")
            end
        else
            show_osd("Secondary Subtitles: OFF")
        end
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
-- SYSTEM EVENTS
-- =========================================================================

-- =========================================================================
-- SYSTEM EVENTS
-- =========================================================================

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
    
    -- Primary: Internal tracks (Requirement: Unified Source Fallback / OSD-Independent)
    if ctext == "" and time_pos then
        local pri_idx = get_center_index(Tracks.pri.subs, time_pos)
        local sec_idx = get_center_index(Tracks.sec.subs, time_pos)
        
        local pri_s = (pri_idx ~= -1) and Tracks.pri.subs[pri_idx]
        local sec_s = (sec_idx ~= -1) and Tracks.sec.subs[sec_idx]
        
        local pri_line = (pri_s and time_pos >= pri_s.start_time and time_pos <= pri_s.end_time) and pri_s.text or ""
        local sec_line = (sec_s and time_pos >= sec_s.start_time and time_pos <= sec_s.end_time) and sec_s.text or ""
        
        if pri_line ~= "" or sec_line ~= "" then
            ctext = pri_line .. ((pri_line ~= "" and sec_line ~= "") and "\n" or "") .. sec_line
        end
    end

    -- Fallback: Native properties (if internal data unavailable)
    if ctext == "" then
        local p_text = mp.get_property("sub-text") or ""
        local s_text = mp.get_property("secondary-sub-text") or ""
        if p_text ~= "" or s_text ~= "" then
            ctext = p_text .. ((p_text ~= "" and s_text ~= "") and "\n" or "") .. s_text
        end
    end
    
    -- Clean text (remove ASS tags)
    ctext = ctext:gsub("{[^}]+}", ""):gsub("\\N", "\n")
    
    local final_text = ""
    
    if is_context then
        -- Context Copy already filtered lines internally, just join whatever it gave us
        final_text = ctext:gsub("\n", " ")
    else
        local lines = {}
        for raw_line in ctext:gmatch("[^\n]+") do
            local line = raw_line:match("^%s*(.-)%s*$")
            if line and line ~= "" then table.insert(lines, line) end
        end
        
        if #lines > 0 then
            local valid = {}
            if Options.copy_filter_russian then
                for _, ln in ipairs(lines) do
                    local cyr = has_cyrillic(ln)
                    if (FSM.COPY_MODE == "A" and not cyr) or (FSM.COPY_MODE == "B" and cyr) then table.insert(valid, ln) end
                end
                
                if #valid == 0 then table.insert(valid, (FSM.COPY_MODE == "A") and lines[1] or lines[#lines]) end
            else
                table.insert(valid, (FSM.COPY_MODE == "A") and lines[1] or lines[#lines])
            end
            final_text = table.concat(valid, " ")
        end
    end
    
    if final_text ~= "" then
        set_clipboard(final_text)
        
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

mp.observe_property("sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then print("[LLS ERROR] sid observer: " .. tostring(err)) end
end)
mp.observe_property("secondary-sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then print("[LLS ERROR] sec-sid observer: " .. tostring(err)) end
end)
mp.observe_property("track-list", "native", function()
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then print("[LLS ERROR] track-list observer: " .. tostring(err)) end
    if Options.font_scaling_enabled then
        local ok2, err2 = xpcall(update_font_scale, debug.traceback)
        if not ok2 then print("[LLS ERROR] font-scaling: " .. tostring(err2)) end
    end
end)
mp.observe_property("osd-dimensions", "native", function()
    dw_tooltip_osd:update()
    if Options.font_scaling_enabled then
        local ok, err = xpcall(update_font_scale, debug.traceback)
        if not ok then print("[LLS ERROR] osd-dim observer: " .. tostring(err)) end
    end
end)

mp.observe_property("pause", "bool", function(name, paused)
    if not paused then
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
    end
end)

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
mp.add_key_binding(nil, "toggle-book-mode", toggle_book_mode)
mp.add_key_binding(nil, "lls-seek_prev", function(t) cmd_seek_with_repeat(-1, t) end, {complex = true})
mp.add_key_binding(nil, "lls-seek_next", function(t) cmd_seek_with_repeat(1, t) end, {complex = true})
mp.add_key_binding(nil, "toggle-anki-global", cmd_toggle_anki_global)
mp.add_key_binding(nil, "toggle-record-file", cmd_open_record_file)

local function register_global_position_keys()
    local function bind(opt, name, fn)
        if not opt or opt == "" then return end
        local i = 1
        for key in opt:gmatch("[^%s,;]+") do
            mp.add_key_binding(key, name .. "-" .. i, fn)
            i = i + 1
        end
    end
    bind(Options.key_sub_pos_up, "lls-sub-pos-up", function() cmd_adjust_sub_pos(-1) end)
    bind(Options.key_sub_pos_down, "lls-sub-pos-down", function() cmd_adjust_sub_pos(1) end)
    bind(Options.key_sec_sub_pos_up, "lls-sec-sub-pos-up", function() cmd_adjust_sec_sub_pos(-1) end)
    bind(Options.key_sec_sub_pos_down, "lls-sec-sub-pos-down", function() cmd_adjust_sec_sub_pos(1) end)
end
register_global_position_keys()

if Options.anki_sync_period > 0 then
    mp.add_periodic_timer(Options.anki_sync_period, function()
        local ok, err = xpcall(function()
            find_source_url()
            load_anki_tsv(true)
            drum_osd:update()
            if dw_osd then dw_osd:update() end
        end, debug.traceback)
        if not ok then print("[LLS ERROR] periodic sync: " .. tostring(err)) end
    end)
end
print("[LLS] SCRIPT LOADED SUCCESSFULLY")
---------------------------------------------------------------------------
-- Safety Net: Recover stuck OSD properties from previous crashes
---------------------------------------------------------------------------
local function recover_native_osd_style()
    local opt_style = mp.get_property("options/osd-border-style")
    local cur_style = mp.get_property("osd-border-style")
    if opt_style and cur_style and opt_style ~= cur_style then
        mp.set_property("osd-border-style", opt_style)
    end
end
recover_native_osd_style()
