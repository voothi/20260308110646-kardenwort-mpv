-- =========================================================================
-- KARDENWORT Language Acquisition Suite (LAS) Core
-- Version: v1.58.54
-- Purpose: Language Acquisition through Subtitle-Driven Immersion
-- Features: Autopause, Karaoke Drill, Flashback Replay, Sticky Hold.
-- =========================================================================

local mp = require 'mp'
local script_dir = mp.get_script_directory()
if script_dir then
    package.path = script_dir .. "/?.lua;" .. package.path
end

local utils = require 'mp.utils'
local options = require 'mp.options'
local msg = require 'mp.msg'
require 'resume'

-- Fallback for older mpv versions missing utils.read_file
local function safe_read_file(path)
    if not path or path == "" then return nil end
    if utils and utils.read_file then
        return utils.read_file(path)
    end
    local f = io.open(path, "rb")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end
    return nil
end


-- =========================================================================
-- KARDENWORT CORE CONFIGURATION
-- =========================================================================

-- Forward declarations for interactive logic
local manage_dw_bindings
local update_interactive_bindings
local Options
local DRUM_DRAW_CACHE, DW_DRAW_CACHE, DW_TOOLTIP_DRAW_CACHE
DW_TOOLTIP_DRAW_CACHE = { target_idx = -1, osd_y = -1, version = -1, cl = -1, cw = -1, av = -1 }


-- =========================================================================
-- DIAGNOSTIC & LOGGING SYSTEM
-- =========================================================================
local Diagnostic = {
    ERROR = 0, WARN = 1, INFO = 2, DEBUG = 3, TRACE = 4,
    LEVEL_MAP = { ["error"] = 0, ["warn"] = 1, ["info"] = 2, ["debug"] = 3, ["trace"] = 4 },
    SEEN = {}
}

Diagnostic.log = function(level, text, dedupe_key)
    local log_level_str = (Options and Options.log_level) or "info"
    local current_level = Diagnostic.LEVEL_MAP[log_level_str:lower()] or Diagnostic.INFO
    if level > current_level then return end
    
    if dedupe_key then
        if Diagnostic.SEEN[dedupe_key] then return end
        Diagnostic.SEEN[dedupe_key] = true
    end
    
    local prefix = "[kardenwort]"
    if level == Diagnostic.ERROR then 
        msg.error(prefix .. " " .. text)
    elseif level == Diagnostic.WARN then
        msg.warn(prefix .. " " .. text)
    elseif level == Diagnostic.INFO then
        msg.info(prefix .. " " .. text)
    elseif level == Diagnostic.DEBUG then
        msg.verbose(prefix .. " " .. text)
    elseif level == Diagnostic.TRACE then
        msg.debug(prefix .. " " .. text)
    end
end

Diagnostic.error = function(text, key) Diagnostic.log(Diagnostic.ERROR, text, key) end
Diagnostic.warn  = function(text, key) Diagnostic.log(Diagnostic.WARN, text, key) end
Diagnostic.info  = function(text, key) Diagnostic.log(Diagnostic.INFO, text, key) end
Diagnostic.debug = function(text, key) Diagnostic.log(Diagnostic.DEBUG, text, key) end
Diagnostic.trace = function(text, key) Diagnostic.log(Diagnostic.TRACE, text, key) end

Diagnostic.info("SCRIPT INITIALIZING: " .. (script_dir or mp.get_script_name() or "kardenwort"))

-- Initialize user-data properties for IPC querying
mp.set_property("user-data/kardenwort/last_clipboard", "")
mp.set_property("user-data/kardenwort/last_export", "")
mp.set_property("user-data/kardenwort/last_osd", "")
mp.set_property("user-data/kardenwort/state", "{}")
mp.set_property("user-data/kardenwort/render", "")

local function is_valid_mpv_key(k_str)
    if not k_str or k_str == "" then return false end
    local base = k_str:gsub("Ctrl%+", ""):gsub("Shift%+", ""):gsub("Alt%+", ""):gsub("Meta%+", "")
    local _, count = base:gsub("[%z\1-\127\194-\244][\128-\191]*", "")
    if count > 1 and base:match("[%z\128-\255]") then return false end
    return true
end

-- [v1.58.40] Automatic Russian Layout Expansion
local EN_RU_MAP = {
    ["a"]="ф", ["b"]="и", ["c"]="с", ["d"]="в", ["e"]="у", ["f"]="а", ["g"]="п", ["h"]="р",
    ["i"]="ш", ["j"]="о", ["k"]="л", ["l"]="д", ["m"]="ь", ["n"]="т", ["o"]="щ", ["p"]="з",
    ["q"]="й", ["r"]="к", ["s"]="ы", ["t"]="е", ["u"]="г", ["v"]="м", ["w"]="ц", ["x"]="ч",
    ["y"]="н", ["z"]="я", ["["]="х", ["]"]="ъ", [";"]="ж", ["'"]="э", [","]="б", ["."]="ю", ["`"]="ё"
}

local function expand_ru_keys(key_string, opt_name)
    if not key_string or key_string == "" then return {} end
    local results = {}
    local seen = {}
    
    local function add(k)
        if k and k ~= "" and not seen[k] then
            table.insert(results, k)
            seen[k] = true
        end
    end

    for key in key_string:gmatch("[^%s,;]+") do
        add(key)
        
        -- Attempt to find RU equivalent
        local mods = key:match("^(.*%+)") or ""
        local base = key:sub(#mods + 1)
        
        -- Detect Shift states
        local is_explicit_shift = mods:lower():find("shift")
        local is_implicit_shift = (#base == 1 and base:match("%u"))
        
        local ru_base = EN_RU_MAP[base:lower()]
        if ru_base then
            local ru_upper = {
                ["ф"]="Ф", ["и"]="И", ["с"]="С", ["в"]="В", ["у"]="У", ["а"]="А", ["п"]="П", ["р"]="Р",
                ["ш"]="Ш", ["о"]="О", ["л"]="Л", ["д"]="Д", ["ь"]="Ь", ["т"]="Т", ["щ"]="Щ", ["з"]="З",
                ["й"]="Й", ["к"]="К", ["ы"]="Ы", ["е"]="Е", ["г"]="Г", ["м"]="М", ["ц"]="Ц", ["ч"]="Ч",
                ["н"]="Н", ["я"]="Я", ["х"]="Х", ["ъ"]="Ъ", ["ж"]="Ж", ["э"]="Э", ["б"]="Б", ["ю"]="Ю", ["ё"]="Ё"
            }
            
            if is_explicit_shift then
                -- [v1.58.42 FIX] Shift+e -> "У" only (uppercase Cyrillic, no Shift+ prefix).
                -- Rationale: mpv on Windows normalizes Shift+CyrillicLower == CyrillicUpper.
                -- Registering "Shift+у" is equivalent to "У" in mpv's input table, BUT
                -- some Windows mpv builds also match "Shift+у" against the bare key "у",
                -- creating a false positive. The correct and unambiguous form is the uppercase
                -- character alone (stripped of the Shift+ modifier for the RU variant).
                -- Non-Shift modifiers (Ctrl, Alt) are preserved.
                local other_mods = mods:gsub("[Ss]hift%+", "")
                if ru_upper[ru_base] then add(other_mods .. ru_upper[ru_base]) end
            elseif is_implicit_shift then
                -- E -> У (Only) — implicit shift via uppercase EN letter
                if ru_upper[ru_base] then add(mods .. ru_upper[ru_base]) end
            else
                -- e -> у (Only) — strict lowercase, no bleed into shifted variants
                add(mods .. ru_base)
            end
        end
    end
    
    if opt_name and Options.log_level == "debug" then
        local list = table.concat(results, ", ")

    end
    
    return results
end

local function validate_config()
    local errors = {}
    local function check_keys(opt_val, opt_name)
        if not opt_val or opt_val == "" then return end
        for key in opt_val:gmatch("[^%s,;]+") do
            if not is_valid_mpv_key(key) then
                table.insert(errors, string.format("Invalid key name in '%s': '%s' (multicharacter non-ASCII names are not supported).", opt_name, key))
            end
        end
    end
    
    local key_opts = {
        "dw_key_add", "dw_key_pair", "dw_key_select", "dw_key_seek_prev", "dw_key_seek_next",
        "dw_key_search", "dw_key_copy", "dw_key_seek", "dw_key_esc", "dw_key_jump_left",
        "dw_key_jump_right", "dw_key_jump_select_left", "dw_key_jump_select_right",
        "dw_key_scroll_up", "dw_key_scroll_down", "dw_key_jump_select_up",
        "dw_key_jump_select_down", "dw_key_select_left", "dw_key_select_right",
        "dw_key_select_up", "dw_key_select_down", "dw_key_open_record",
        "dw_key_cycle_copy_mode", "dw_key_toggle_copy_context", "dw_key_tooltip_pin",
        "dw_key_tooltip_hover", "dw_key_tooltip_toggle", "key_sub_pos_up", "key_sub_pos_down",
        "key_sec_sub_pos_up", "key_sec_sub_pos_down"
    }
    
    for _, opt in ipairs(key_opts) do check_keys(Options[opt], "kardenwort-" .. opt) end
    
    if #errors > 0 then
        local summary = "CONFIGURATION HEALTH CHECK FAILED:\n"
        for _, err in ipairs(errors) do summary = summary .. "  - " .. err .. "\n" end
        summary = summary .. "Please correct these in your mpv.conf to avoid unexpected behavior."
        Diagnostic.warn(summary, "startup-health-check")
    else

    end
end


Options = {
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
    drum_active_color = "FFFFFF",   -- White (BGR: FFFFFF | RGB: #FFFFFF)
    drum_active_bold = false,
    drum_active_size_mul = 1.0,
    drum_line_height_mul = 0.87,
    drum_bg_color = "000000",       -- Black (BGR: 000000 | RGB: #000000)
    drum_bg_opacity = "60",         -- background opacity (00-FF, 00 is opaque)
    drum_border_size = 1.5,
    drum_shadow_offset = 1.0,
    drum_double_gap = true,
    drum_vsp = 0,
    drum_block_gap_mul = -0.27,
    drum_gap_adj = 6,
    drum_track_gap = 5.0,         -- Extra spacing between dual tracks (%)
    drum_scrolloff = 0,           -- margin lines for Drum Mode mini viewport (0 = no reserved margin)
    drum_pri_highlight_color = "00CCFF", -- Gold (BGR: 00CCFF | RGB: #FFCC00)
    drum_sec_highlight_color = "00CCFF",
    drum_pri_ctrl_select_color = "FF88FF", -- Pink (BGR: FF88FF | RGB: #FF88FF)
    drum_sec_ctrl_select_color = "FF88FF",
    drum_pri_highlight_bold = false,
    drum_sec_highlight_bold = false,
    -- Interactivity Toggles (Per-Screen, Per-Mode)
    osd_interactivity = true,       -- Master toggle
    dw_pri_interactivity = true,    -- Drum Window: Main Text
    dw_sec_interactivity = true,    -- Drum Window: Tooltip (E)
    drum_pri_interactivity = true,  -- Drum Mode: Primary Track
    drum_sec_interactivity = true,  -- Drum Mode: Secondary Track
    srt_pri_interactivity = true,   -- Regular SRT: Primary Track
    srt_sec_interactivity = true,   -- Regular SRT: Secondary Track

    -- Highlighting Toggles (Per-Screen, Per-Mode)
    dw_pri_highlighting = true,     -- Drum Window: Main Text
    dw_sec_highlighting = true,     -- Drum Window: Tooltip (E)
    drum_pri_highlighting = true,   -- Drum Mode: Primary Track
    drum_sec_highlighting = true,   -- Drum Mode: Secondary Track
    srt_pri_highlighting = true,    -- Regular SRT: Primary Track
    srt_sec_highlighting = true,    -- Regular SRT: Secondary Track

    -- SRT Style (Regular Mode)
    srt_font_size = 34,
    srt_font_name = "Consolas",
    srt_font_bold = false,
    srt_active_color = "FFFFFF",   -- White (BGR: FFFFFF | RGB: #FFFFFF)
    srt_context_color = "CCCCCC",  -- Surrounding lines color
    srt_active_opacity = "00",     -- Transparency for active line
    srt_context_opacity = "30",    -- Transparency for context lines
    srt_bg_color = "000000",       -- Black (BGR: 000000 | RGB: #000000)
    srt_bg_opacity = "60",         -- Shadow/Frame transparency
    srt_border_size = 1.5,
    srt_shadow_offset = 1.0,
    srt_double_gap = true,
    srt_vsp = 0,
    srt_block_gap_mul = -0.27,
    srt_line_height_mul = 0.87,     -- Vertical spacing multiplier
    srt_pri_highlight_color = "00CCFF", -- Gold (BGR: 00CCFF | RGB: #FFCC00)
    srt_sec_highlight_color = "00CCFF",
    srt_pri_ctrl_select_color = "FF88FF", -- Pink (BGR: FF88FF | RGB: #FF88FF)
    srt_sec_ctrl_select_color = "FF88FF",
    srt_pri_highlight_bold = false,
    srt_sec_highlight_bold = false,

    -- Copy Mode
    copy_default_mode = "A",
    copy_filter_russian = true,
    copy_context_lines = 2,
    copy_word_limit = 3,
    copy_osd_cooldown = 3.0,
    key_copy_popup = "Shift+C",
    key_copy_main = "Alt+c",

    -- Toggle Positions
    -- [NOTE] sec_pos_bottom should be ~5% LESS than sub-pos in mpv.conf 
    -- to prevent primary and secondary subtitles from overlapping at the bottom.
    sec_pos_top = 10,
    sec_pos_bottom = 90,

    -- System
    tick_rate = 0.05,
    osd_duration = 0.5,
    win_clipboard_retries = 5,
    win_clipboard_retry_delay = 50, -- milliseconds
    gd_trigger_enabled = "no",
    gd_hotkey_popup = "Ctrl+Alt+Shift+Q",
    gd_hotkey_main = "Ctrl+Alt+Shift+1",
    gd_trigger_method = "powershell", -- "powershell" or "python"
    python_path = "python",
    python_trigger_delay_popup = 0.1,
    python_trigger_delay_main = 0.5,
    gd_trigger_lock_duration = 2.0,

    -- Drum Window
    dw_font_size = 34,
    dw_key_copy = "Ctrl+c Ctrl+с",
    dw_lines_visible = 15,        -- how many lines visible in the window
    dw_scrolloff = 3,             -- margin lines at top/bottom before scrolling
    dw_bg_color = "000000",       -- Black (BGR: 000000 | RGB: #000000)
    dw_bg_opacity = "60",         -- background opacity (00-FF, 00 is opaque)
    dw_context_color = "CCCCCC",  -- light text
    dw_active_color = "FFFFFF",   -- White (BGR: FFFFFF | RGB: #FFFFFF)
    dw_active_bold = false,
    dw_context_bold = false,
    dw_active_opacity = "00",     -- text alpha for active playback line
    dw_context_opacity = "30",    -- text alpha for context lines
    dw_active_size_mul = 1.0,
    dw_context_size_mul = 1.0,
    dw_highlight_color = "00CCFF",-- Gold (BGR: 00CCFF | RGB: #FFCC00)
    dw_ctrl_select_color = "FF88FF",-- Pink (BGR: FF88FF | RGB: #FF88FF)
    dw_highlight_bold = false,
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
    search_bg_opacity = "60",        -- background opacity (00-FF, 00 is opaque)
    search_text_color = "CCCCCC",
    search_border_size = 1.5,
    search_shadow_offset = 1.0,
    search_line_height_mul = 1.2,
    search_hit_color = "0088FF",       -- Orange (BGR: 0088FF | RGB: #FF8800)
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
    tooltip_bg_color = "000000",       -- Background color (BGR hex)
    tooltip_bg_opacity = "60",         -- Background transparency
    tooltip_border_size = 1.2,
    tooltip_shadow_offset = 1.0,
    tooltip_line_height_mul = 0.87,     -- Vertical spacing multiplier
    tooltip_block_gap_mul = -0.27,
    tooltip_double_gap = true,         -- Use double newline (\N\N) between context lines
    tooltip_vsp = 0,                   -- Vertical spacing adjustment (pixels)
    tooltip_y_offset_lines = 0,        -- Vertical shift in number of lines (positive = down, negative = up)
    tooltip_highlight_color = "00CCFF",-- Gold (BGR: 00CCFF | RGB: #FFCC00)
    tooltip_ctrl_select_color = "FF88FF",-- Pink (BGR: FF88FF | RGB: #FF88FF)
    tooltip_active_bold = false,
    tooltip_context_bold = false,
    tooltip_highlight_bold = false,

    -- Navigation Repeat
    seek_hold_delay = 0.5,
    seek_hold_rate = 10,

    -- Anki Highlighter
    dw_key_add = "g MBTN_MID Ctrl+MBTN_MID",
    dw_key_pair = "f Ctrl+MBTN_LEFT",
    dw_key_select = "MBTN_LEFT",
    dw_key_pair_mod = "Ctrl",
    dw_key_tooltip_pin = "MBTN_RIGHT",
    dw_key_tooltip_hover = "n",
    dw_key_tooltip_toggle = "e",
    dw_key_seek_prev = "a",
    dw_key_seek_next = "d",
    dw_key_search = "Ctrl+f",

    dw_key_seek = "ENTER KP_ENTER",
    dw_key_replay = "s",
    dw_key_esc = "ESC",
    dw_key_select_extend = "Shift+MBTN_LEFT",
    dw_key_mouse_seek = "MBTN_LEFT_DBL",
    dw_key_jump_left = "Ctrl+LEFT",
    dw_key_jump_right = "Ctrl+RIGHT",
    dw_key_jump_select_left = "Ctrl+Shift+LEFT",
    dw_key_jump_select_right = "Ctrl+Shift+RIGHT",
    dw_key_scroll_up = "Ctrl+UP",
    dw_key_scroll_down = "Ctrl+DOWN",
    dw_key_jump_select_up = "Ctrl+Shift+UP",
    dw_key_jump_select_down = "Ctrl+Shift+DOWN",
    dw_key_select_left = "Shift+LEFT",
    dw_key_select_right = "Shift+RIGHT",
    dw_key_select_up = "Shift+UP",
    dw_key_select_down = "Shift+DOWN",
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
    search_key_paste = "Ctrl+v",
    search_key_select_all = "Ctrl+a",
    search_key_delete_word = "Ctrl+w",
    search_key_click = "MBTN_LEFT",
    dw_key_open_record = "o",
    key_sub_pos_up = "r",
    key_sub_pos_down = "t",
    key_sec_sub_pos_up = "R",
    key_sec_sub_pos_down = "T",

    anki_context_max_words = 40,
    anki_context_span_pad = 3,        -- Extra words added before/after a wide paired selection
    anki_highlight_depth_1 = "0075D1",    -- Orange (BGR: 0075D1 | RGB: #D17500)
    anki_highlight_depth_2 = "005DAE",
    anki_highlight_depth_3 = "003C88",
    anki_split_depth_1 = "FF88B0",        -- Purple (BGR: FF88B0 | RGB: #B088FF)
    anki_split_depth_2 = "D10069",
    anki_split_depth_3 = "A30052",
    anki_mix_depth_1 = "4A4AD3",          -- Brick (BGR: 4A4AD3 | RGB: #D34A4A)
    anki_mix_depth_2 = "3636A8",
    anki_mix_depth_3 = "151578",
    anki_global_highlight = false,
    anki_record_file = "",
    log_level = "info",
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
    dw_mouse_shield_ms = 50,       -- Interaction Shield window (ms)
    sentence_word_threshold = 3,
    replay_ms = 2000,              -- Fixed window for adaptive replay (ms)
    replay_count = 2,              -- Number of iterations for the replay command
    replay_autostop = true,        -- Whether to pause after iterations (Autopause ON only)
    audio_padding_start = 1000,    -- Pre-roll buffer in ms
    audio_padding_end = 1000,      -- Post-roll buffer in ms
    -- [v1.58.51] Behavioral Parameters
    nav_cooldown = 0.2,           -- Settle period after manual seek (sec)
    nav_tolerance = 0.05,         -- Overlap priority threshold (sec)
    autopause_overshoot = 0.1,     -- Permitted overshoot past boundary (sec)
    key_cycle_immersion_mode = "O Щ", -- Hotkey to cycle Phrase/Movie modes
    immersion_mode_default = "PHRASE", -- Default mode at startup ("PHRASE" or "MOVIE")
    seek_time_delta = 2,           -- Amount to seek in seconds for relative time navigation
    seek_osd_duration = 2.0,       -- Duration of the centered seek OSD message (sec)
    seek_font_size = 60,
    seek_font_name = "Consolas",
    seek_font_bold = false,
    seek_color = "FFFFFF",
    seek_bg_color = "000000",
    seek_bg_opacity = "60",
    seek_border_size = 1.5,
    seek_shadow_offset = 1.0,
    seek_show_accumulator = true,
    seek_msg_format = "%p%v",
    seek_msg_cumulative_format = "%P%V",
    replay_msg_format = "Replay: %mms%x",
    replay_on_msg_format = "Replaying segment: %mms%x"
}
options.read_options(Options, "kardenwort")

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
    ACTIVE_IDX = -1, -- The "Sentinel" source of truth for active subtitle context
    SEC_ACTIVE_IDX = -1, -- Secondary-track Sticky Sentinel (mirrors ACTIVE_IDX logic for translation track)
    IMMERSION_MODE = (Options.immersion_mode_default == "MOVIE") and "MOVIE" or "PHRASE", -- "PHRASE" (Padded boundaries) or "MOVIE" (Gapless focus)
    JUST_JERKED_TO = -1, -- Flag to prevent loop during Phrase overlap jerk-back
    MANUAL_NAV_COOLDOWN = 0, -- Cooldown timestamp to suspend smart logic after seek
    SEEK_ACCUMULATOR = 0,
    SEEK_LAST_TIME = 0,
    SEEK_PRESS_COUNT = 0,

    -- Transients
    last_paused_sub_end = nil,
    last_time_pos = nil,
    IGNORE_NEXT_JUMP = false,
    TIMESEEK_INHIBIT_UNTIL = nil, -- Suppress autopause during backward time-seek transit
    REWIND_START_IDX = nil,      -- Starting subtitle index when rewind began (for within-subtitle detection)
    REWIND_TRANSIT_CROSS_CARD = false, -- True only when backward time-seek crosses subtitle card boundary
    LOOP_MODE = "OFF",
    LOOP_ARMED = false,
    LOOP_START = nil,
    LOOP_END = nil,
    SCHEDULED_REPLAY_START = nil,
    SCHEDULED_REPLAY_END = nil,
    REPLAY_REMAINING = 0,
    GHOST_HOLD_EXPIRY = nil,
    PHYSICAL_SPACE_HOLD = false,
    space_down_time = 0,
    space_up_time = 0,
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
    DW_NAV_ACTIVATION_GUARD_UNTIL = nil, -- Suppress immediate key-repeat after null-pointer activation
    DW_VIEW_CENTER = -1,       -- Viewport center line index
    DW_FOLLOW_PLAYER = true,   -- Follow active playback line?
    DW_KEY_OVERRIDE = false,   -- Are we overriding arrow keys?
    DW_MOUSE_DRAGGING = false, -- True while LMB is held and dragging
    DW_CTRL_HELD = false,      -- True while Ctrl key is held in DW
    DW_CTRL_PENDING_SET = {},  -- Non-contiguous word selection map {line -> {word -> {line, word}}}
    DW_CTRL_PENDING_LIST = {}, -- Sorted list of members for sequential export
    DW_MOUSE_SCROLL_TIMER = nil, -- Timer for auto-scroll while dragging at edges

    -- Performance Caches
    DW_LAYOUT_CACHE = nil,     -- Cached layout for the current viewport
    LAYOUT_VERSION = 0,        -- Incremented when font/spacing options change
    -- Global Search State
    SEARCH_MODE = false,
    SEARCH_QUERY = "",
    SEARCH_RESULTS = {},
    SEARCH_SEL_IDX = 1,
    SEARCH_CURSOR = 0,
    SEARCH_ANCHOR = -1,
    SEARCH_CHAR_BINDINGS = {},

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
    DW_TOOLTIP_HIT_ZONES = nil, -- Hit-zone metadata for active tooltip interaction
    DW_ACTIVE_LINE = -1,        -- Currently playing subtitle index
    DW_TOOLTIP_TARGET_MODE = "ACTIVE", -- Target switching for forced tooltip ("ACTIVE" or "CURSOR")
    DW_TOOLTIP_SEC_SUBS = {},   -- Cached secondary subtitles for tooltip fallback when secondary track is hidden
    DW_TOOLTIP_SEC_PATH = nil,  -- Source path for DW_TOOLTIP_SEC_SUBS
    DW_SEEKING_MANUALLY = false,
    DW_SEEK_TARGET = -1,
    DW_MOUSE_LOCK_UNTIL = 0,         -- Timestamp to ignore mouse events (shielding)

    -- Repeat Timer
    SEEK_REPEAT_TIMER = nil,

    -- Anki Highlighter State
    ANKI_HIGHLIGHTS = {},
    ANKI_HIGHLIGHTS_SORTED = {},
    ANKI_VERSION = 0,             -- Version counter for cache invalidation
    ANKI_DB_PATH = nil,
    ANKI_DB_MTIME = 0,
    ANKI_DB_SIZE = 0
}

local Tracks = {
    pri = { id = 0, is_ass = false, path = nil, subs = {} },
    sec = { id = 0, is_ass = false, path = nil, subs = {} }
}

-- =========================================================================
-- CORE UTILITIES (Moved up for visibility)
-- =========================================================================

function show_osd(msg, dur)
    local style = mp.get_property("osd-ass-cc/0") or ""
    -- IPC diagnostics contract used by acceptance tests
    mp.set_property("user-data/kardenwort/last_osd", tostring(msg or ""))
    mp.osd_message(style .. "{\\an4}{\\fs20}" .. msg, dur or Options.osd_duration)
end

local seek_osd = mp.create_osd_overlay("ass-events")
seek_osd.res_y = Options.font_base_height
seek_osd.res_x = math.floor(seek_osd.res_y * 16 / 9)
seek_osd.z = 40
local seek_timer = nil

function show_seek_osd(msg, alignment)
    local ass = ""
    ass = ass .. string.format("{\\an%d}", alignment)
    
    -- Derived positioning based on global resolution settings.
    local ry = Options.font_base_height
    local rx = math.floor(ry * 16 / 9)
    local cy = ry / 2
    local cx_padding = 40
    
    if alignment == 4 then
        ass = ass .. string.format("{\\pos(%d, %d)}", cx_padding, cy)
    elseif alignment == 6 then
        ass = ass .. string.format("{\\pos(%d, %d)}", rx - cx_padding, cy)
    end
    
    ass = ass .. string.format("{\\fn%s}", Options.seek_font_name)
    ass = ass .. string.format("{\\fs%d}", Options.seek_font_size)
    ass = ass .. string.format("{\\b%d}", Options.seek_font_bold and 1 or 0)
    ass = ass .. string.format("{\\1c&H%s&}", Options.seek_color)
    ass = ass .. string.format("{\\3c&H%s&}", Options.seek_bg_color)
    ass = ass .. string.format("{\\4c&H%s&}", Options.seek_bg_color)
    ass = ass .. string.format("{\\3a&H%s&}", Options.seek_bg_opacity)
    ass = ass .. string.format("{\\4a&H%s&}", Options.seek_bg_opacity)
    ass = ass .. string.format("{\\bord%g}", Options.seek_border_size)
    ass = ass .. string.format("{\\shad%g}", Options.seek_shadow_offset)
    
    seek_osd.data = ass .. msg
    seek_osd:update()
    
    if seek_timer then seek_timer:kill() end
    seek_timer = mp.add_timeout(Options.seek_osd_duration, function()
        seek_osd.data = ""
        seek_osd:update()
    end)
end

function has_cyrillic(str)
    if not str then return false end
    return str:match("[\208-\209][\128-\191]") ~= nil
end

local function get_effective_boundaries(subs, sub, idx)
    if not sub then return nil, nil end
    local pad_start = (Options.audio_padding_start or 0) / 1000
    local pad_end = (Options.audio_padding_end or 0) / 1000
    
    local start = sub.start_time - pad_start
    local stop = sub.end_time + pad_end
    
    -- [v1.58.51] Movie Mode: Seamless handover at the next subtitle's padded start.
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

function get_center_index(subs, time_pos)
    if not subs or #subs == 0 then return -1 end
    
    -- [v1.58.51] Sticky Focus Sentinel: Prioritize the active index if we are within its padded window.
    -- This prevents "Magnetic Snapping" to adjacent subtitles when the playhead is in the padding gap.
    -- [20260507154518] Extended to secondary track via FSM.SEC_ACTIVE_IDX to prevent desync when
    -- padded windows overlap (audio_padding_end + audio_padding_start > inter-subtitle gap).
    local active_idx = (subs == Tracks.pri.subs) and FSM.ACTIVE_IDX or
                       (subs == Tracks.sec.subs and FSM.SEC_ACTIVE_IDX or -1)

    -- [v1.58.51] Jerk-Back Loop Prevention: If we just jumped to a new index in Phrases mode,
    -- don't let the sticky logic pull us back to the previous one during the overlap.
    if FSM.IMMERSION_MODE == "PHRASE" and FSM.JUST_JERKED_TO ~= -1 then
        active_idx = FSM.JUST_JERKED_TO
    end

    -- [v1.58.53] One-step Natural Progression (per immersion-engine spec).
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
    
    -- [v1.58.52] Absolute Start Guard: If we are at the very beginning, always return first sub
    if time_pos <= 0 then return 1 end

    -- [v1.58.51] Overlap Priority: If we are in a gap where the next sub's
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


local function sync_ctrl_pending_list()
    local members = {}
    for _, line_tbl in pairs(FSM.DW_CTRL_PENDING_SET) do
        for _, m in pairs(line_tbl) do
            table.insert(members, m)
        end
    end
    if #members > 0 then
        table.sort(members, function(a, b)
            if a.line ~= b.line then return a.line < b.line end
            return a.word < b.word
        end)
    end
    FSM.DW_CTRL_PENDING_LIST = members
end


local function dw_reset_selection()
    FSM.DW_CTRL_PENDING_SET = {}
    FSM.DW_CTRL_PENDING_LIST = {}
    FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    FSM.DW_CURSOR_WORD = -1
    FSM.DW_CURSOR_X = nil
    if FSM.DW_ACTIVE_LINE ~= -1 then
        FSM.DW_CURSOR_LINE = FSM.DW_ACTIVE_LINE
    end
    if FSM.DRUM_WINDOW ~= "OFF" then 
        if dw_osd then dw_osd:update() end
    elseif FSM.DRUM == "ON" then 
        if drum_osd then drum_osd:update() end 
    end
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
    line = line:gsub("\r", ""):gsub("<[^>]+>", ""):gsub("%z", "")
    return line:gsub("^%s*(.-)%s*$", "%1")
end

function load_sub(path, is_ass)
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
                            local raw_text = text:gsub("\\N", " \n "):gsub("{[^}]+}", "")
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
            local line = clean_text_srt(raw_line)
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
                    current_sub.start_time = parse_time(s)
                    current_sub.end_time = parse_time(e)
                    state = "TEXT"
                end
            elseif state == "TEXT" then
                if current_sub.text == "" then
                    current_sub.text = line
                else
                    current_sub.text = current_sub.text .. " \n " .. line
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


-- UI State pointers for Drum Mode OSD
local drum_osd = mp.create_osd_overlay("ass-events")
drum_osd.res_y = Options.font_base_height
drum_osd.res_x = math.floor(drum_osd.res_y * 16 / 9)
drum_osd.z = 10

local dw_osd = mp.create_osd_overlay("ass-events")
dw_osd.res_y = Options.font_base_height
dw_osd.res_x = math.floor(dw_osd.res_y * 16 / 9)
dw_osd.z = 20

local search_osd = mp.create_osd_overlay("ass-events")
search_osd.res_y = Options.font_base_height
search_osd.res_x = math.floor(search_osd.res_y * 16 / 9)
search_osd.z = 30

local dw_tooltip_osd = mp.create_osd_overlay("ass-events")
dw_tooltip_osd.res_y = Options.font_base_height
dw_tooltip_osd.res_x = math.floor(dw_tooltip_osd.res_y * 16 / 9)
dw_tooltip_osd.z = 25

local dw_ensure_visible -- forward declaration

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

function cmd_cycle_immersion_mode()
    if FSM.IMMERSION_MODE == "PHRASE" then
        FSM.IMMERSION_MODE = "MOVIE"
    else
        FSM.IMMERSION_MODE = "PHRASE"
        -- Synchronize ACTIVE_IDX to prevent phantom "Jerk Back" on mode switch
        local time_pos = mp.get_property_number("time-pos") or 0
        local subs = Tracks.pri.subs
        if subs and #subs > 0 then
            FSM.ACTIVE_IDX = get_center_index(subs, time_pos)
        end
        if Tracks.sec.subs and #Tracks.sec.subs > 0 then
            FSM.SEC_ACTIVE_IDX = get_center_index(Tracks.sec.subs, time_pos)
        end
    end
    show_osd("Immersion Mode: " .. FSM.IMMERSION_MODE)
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
    
    local paths = {
        -- Preferred modern root location (kebab-case), then underscore variant.
        utils.join_path(mp.get_script_directory(), "../../anki-mapping.ini"),
        utils.join_path(mp.get_script_directory(), "../../anki_mapping.ini"),
        -- MPV-config-relative root fallback.
        mp.command_native({"expand-path", "~~/anki-mapping.ini"}),
        mp.command_native({"expand-path", "~~/anki_mapping.ini"}),
        -- Legacy script-opts fallback for backward compatibility.
        mp.command_native({"expand-path", "~~/script-opts/anki-mapping.ini"}),
        mp.command_native({"expand-path", "~~/script-opts/anki_mapping.ini"})
    }
    local f = nil
    for _, p in ipairs(paths) do
        f = io.open(p, "r")
        if f then break end
    end
    local config = {
        fields = {},
        mapping = {},
        mapping_word = {},
        mapping_sentence = {},
        ordered_word = {},
        ordered_sentence = {},
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
                    table.insert(config.ordered_word, k)
                end
            elseif section == "fields_mapping.sentence" then
                local k, v = clean_line:match("^([^=]+)=(.*)$")
                if k and v then
                    k = k:match("^%s*(.-)%s*$")
                    v = v:match("^%s*(.-)%s*$")
                    if (v:match('^".*"$') or v:match("^'.*'$")) then v = v:sub(2, -2) end
                    config.mapping_sentence[k] = v
                    table.insert(config.ordered_sentence, k)
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

-- Module-scope Cyrillic case-mapping tables (created once at load time).
-- Hoisted from utf8_to_lower() to eliminate per-call allocation overhead.
local CYRILLIC_UPPER = utf8_to_table("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ")
local CYRILLIC_LOWER = utf8_to_table("абвгдеёжзийклмнопрстуфхцчшщъыьэюяäöüß")

local CYRILLIC_MAP = {}
for i = 1, #CYRILLIC_UPPER do
    CYRILLIC_MAP[CYRILLIC_UPPER[i]] = CYRILLIC_LOWER[i]
end

local WORD_CHAR_MAP = {}
for _, ch in ipairs(CYRILLIC_UPPER) do WORD_CHAR_MAP[ch] = true end
for _, ch in ipairs(CYRILLIC_LOWER) do WORD_CHAR_MAP[ch] = true end

local function utf8_to_lower(str)
    local res = str:lower()
    return (res:gsub("[%z\1-\127\194-\244][\128-\191]*", CYRILLIC_MAP))
end

local function has_cyrillic(str)
    if not str then return false end
    return str:find("[\208\209]") ~= nil
end

local function is_word_char(c)
    if not c or #c == 0 then return false end
    -- ASCII alphanumeric + apostrophe
    if c:match("^[%w']$") then return true end
    -- German/Russian/Cyrillic support via O(1) lookup map
    return WORD_CHAR_MAP[c] == true
end





local function is_abbrev(w)
    if not w then return false end
    local l_word = w:lower()
    local abbrev_list = " " .. (Options.anki_abbrev_list or ""):lower() .. " "
    if abbrev_list:find(" " .. l_word .. " ", 1, true) then return true end
    if Options.anki_abbrev_smart then
        if w:match("^%l+%.$") and #w <= 5 then return true end
        if w:match("^%u%.$") then return true end
        if w:match("^%u%.%u%.$") then return true end
    end
    return false
end

local function clean_anki_term(term)
    if not term or term == "" then return "" end
    term = term:gsub("{[^}]+}", "")
    term = term:match("^%s*(.-)%s*$")
    return term or ""
end

local L_EPSILON = 0.0001

local function logical_cmp(a, b)
    if not a or not b then return false end
    return math.abs(a - b) < L_EPSILON
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
            
        -- 2. (Metadata brackets now handled by is_word_char/is_word logic)
            
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
            -- Optimization: Pre-calculate normalized lowercase for hot-path matching
            token.lower_clean = utf8_to_lower(token.text:gsub("[%p%s]", ""))
            token.logical_idx = curr_logical_idx
            curr_logical_idx = curr_logical_idx + 1
            curr_sub_idx = 0.1

        -- 5. Handle Line Breaks (Atomize \N, \n, \h)
        elseif c == "\\" and i < n and (chars[i+1] == "N" or chars[i+1] == "n" or chars[i+1] == "h") then
            token.text = c .. chars[i+1]
            token.logical_idx = (curr_logical_idx - 1) + curr_sub_idx
            curr_sub_idx = curr_sub_idx + 0.1
            i = i + 2
            
        -- 6. Handle Punctuation/Misc (Atomic Separator)
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

local function get_sub_tokens(s, force_rich)
    if not s then return nil end
    local use_rich = force_rich or Options.dw_original_spacing
    
    if use_rich then
        if not s.tokens_rich then
            local raw_text = s.text:gsub("\n", " ")
            s.tokens_rich = build_word_list_internal(raw_text, true)
        end
        return s.tokens_rich
    else
        if not s.tokens then
            local raw_text = s.text:gsub("\n", " ")
            s.tokens = build_word_list_internal(raw_text, false)
            local wc = 0
            for _, t in ipairs(s.tokens) do if t.is_word then wc = wc + 1 end end
            s.word_count = wc
        end
        return s.tokens
    end
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
            local no_space_before = next_w:match("^[%.,!?;:…»”%)%]%}]$") 
                                  or next_w:match("^[/-]$") 
                                  or next_w:match("^\226\128\147$") -- en-dash
                                  or next_w:match("^\226\128\148$") -- em-dash
                                  or next_w:match("^[\"']$")
            
            local no_space_after = w:match("^[/-]$") 
                                 or w:match("^\226\128\147$") 
                                 or w:match("^\226\128\148$") 
                                 or w:match("^[«“%(%[%{]$")
                                 or w:match("^[\"']$")

            if not no_space_before and not no_space_after then
                res = res .. " "
            end
        end
    end

    -- Final cleanup: Trim trailing punctuation that shouldn't be part of a vocab term
    -- but might have been captured by the segment boundary logic.
    if #words == 1 then
        -- Only strip brackets/parens if they are balanced at the outer edges
        local outer_bal = (res:match("^%b[]$") or res:match("^%b()$") or res:match("^%b{}$"))
        if outer_bal then
            res = res:sub(2, -2)
        else
            -- Strip terminal punctuation but preserve brackets if they aren't balanced wrappers
            res = res:gsub("[%.,!?;:%s]+$", ""):gsub("^[%s]+", "")
        end
    end

    return res
end


local function prepare_export_text(params, options)
    options = options or {}
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return "" end
    
    local parts = {}
    
    if params.type == "RANGE" then
        local p1_l, p1_w, p2_l, p2_w = params.p1_l, params.p1_w, params.p2_l, params.p2_w
        for i = p1_l, p2_l do
            local sub = subs[i]
            if sub then
                local raw_text = sub.text:gsub("\n", " ")
                local tokens = build_word_list_internal(raw_text, true)
                
                local line_parts = {}
                for _, t in ipairs(tokens) do
                    if t.logical_idx then
                        local in_range = true
                        if i == p1_l and t.logical_idx < p1_w - L_EPSILON then in_range = false end
                        if i == p2_l and t.logical_idx > p2_w + L_EPSILON then in_range = false end
                        
                        if in_range then
                            table.insert(line_parts, t.text)
                        end
                    end
                end
                

                if #line_parts > 0 then
                    table.insert(parts, table.concat(line_parts, ""))
                end
            end
        end
    elseif params.type == "SET" then
        local members = params.members
        local last_m = nil
        for idx, m in ipairs(members) do
            local sub = subs[m.line]
            if sub then
                local raw_text = sub.text:gsub("\n", " ")
                local tokens = build_word_list_internal(raw_text, true)
                local w_text = nil
                

                for _, t in ipairs(tokens) do
                    if logical_cmp(t.logical_idx, m.word) then
                        w_text = t.text
                        break
                    end
                end
                
                if w_text then
                    if last_m then
                        local has_gap = false
                        if m.line == last_m.line then
                            has_gap = (m.word > last_m.word + 1.05)
                        elseif m.line > last_m.line + 1 then
                            has_gap = true
                        else
                            -- Consecutive lines: Check for intermediate words (Requirement 151 Adaptive Gap)
                            local prev_sub_tokens = get_sub_tokens(subs[last_m.line], true)
                            local next_sub_tokens = get_sub_tokens(subs[m.line], true)
                            for _, t in ipairs(prev_sub_tokens) do
                                if t.logical_idx and t.logical_idx > last_m.word + L_EPSILON and t.is_word then
                                    has_gap = true; break
                                end
                            end
                            if not has_gap then
                                for _, t in ipairs(next_sub_tokens) do
                                    if t.logical_idx and t.logical_idx < m.word - L_EPSILON and t.is_word then
                                        has_gap = true; break
                                    end
                                end
                            end
                        end

                        if has_gap then
                            table.insert(parts, " ... ")
                        else
                            -- Requirement 86: Use verbatim tokens between adjacent members
                            if m.line == last_m.line then
                                local last_line_tokens = build_word_list_internal(subs[last_m.line].text:gsub("\n", " "), true)
                                for _, t in ipairs(last_line_tokens) do
                                    if t.logical_idx > last_m.word + L_EPSILON and t.logical_idx < m.word - L_EPSILON then
                                        table.insert(parts, t.text)
                                    end
                                end
                            else
                                table.insert(parts, " ")
                            end
                        end
                    end
                    table.insert(parts, w_text)
                    last_m = m
                    
                end
            end
        end
    elseif params.type == "POINT" then
        local target_subs = (options.copy_mode == "B" and Tracks.sec.subs and #Tracks.sec.subs >= params.line) and Tracks.sec.subs or subs
        local sub = target_subs[params.line]
        if sub then
            local raw_text = sub.text:gsub("\n", " ")
            if params.word and params.word ~= -1 then
                local tokens = build_word_list_internal(raw_text, true)
                for _, t in ipairs(tokens) do
                    if logical_cmp(t.logical_idx, params.word) then
                        parts = {t.text}
                        break
                    end
                end
            else
                parts = {raw_text}
            end
        end
    end
    
    local final_text = table.concat(parts, params.type == "RANGE" and " " or "")
    
    -- Requirement: Unified High-Fidelity Cleaning
    if options.clean then
        final_text = clean_anki_term(final_text)
    else
        final_text = final_text:gsub("{[^}]+}", ""):match("^%s*(.-)%s*$")
    end

    
    -- Post-processing for clipboard Russian filter if needed
    if options.filter_russian then
        local lines = {}
        for ln in final_text:gmatch("[^\n]+") do
            table.insert(lines, ln)
        end
        if #lines > 0 then
            local valid = {}
            for _, ln in ipairs(lines) do
                local cyr = has_cyrillic(ln)
                if (options.copy_mode == "A" and not cyr) or (options.copy_mode == "B" and cyr) then table.insert(valid, ln) end
            end
            if #valid == 0 then table.insert(valid, (options.copy_mode == "A") and lines[1] or lines[#lines]) end
            final_text = table.concat(valid, " ")
        end
    end
    
    return final_text or ""
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

    -- Aggregate all indices for highlighting as a direct lookup map
    -- (char-index -> true) consumed by draw_search_ui().
    local indices_map = {}
    for _, m in ipairs(matches) do
        for _, idx in ipairs(m.indices) do
            indices_map[idx] = true
        end
    end

    return score, indices_map
end




local function calculate_highlight_stack(subs, sub_idx, token_idx, time_pos)
    if not next(FSM.ANKI_HIGHLIGHTS) or not subs or not subs[sub_idx] then return 0, 0, false, {}, 0 end
    
    local tokens = get_sub_tokens(subs[sub_idx])
    if not tokens then return 0, 0, 0, false end
    
    local target_token = tokens[token_idx]
    if not target_token or not target_token.is_word then return 0, 0, false, {}, 0 end
    
    local target_l_idx = target_token.logical_idx
    local target_lower_full = target_token.lower_clean
    if not target_lower_full or target_lower_full == "" then return 0, 0, false, {}, 0 end

    -- Extract subwords for partial matches within compounds (e.g. Netto/Globus, 20–25)
    local target_subsets = { [target_lower_full] = true }
    for sw in target_token.text:gmatch("[^%s/-\226\128\147\226\128\148]+") do
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
    -- Build the candidate list to scan.
    -- Local Mode: binary-search ANKI_HIGHLIGHTS_SORTED to find only entries
    -- within the extended time window, reducing O(H) to O(log H + W).
    -- Global Mode: fall back to scanning all highlights (time-window disabled).
    local candidates
    if not Options.anki_global_highlight and FSM.ANKI_HIGHLIGHTS_SORTED and #FSM.ANKI_HIGHLIGHTS_SORTED > 0 then
        local sub_start = subs[sub_idx].start_time
        local sub_end   = subs[sub_idx].end_time
        -- Use maximum possible window (base + multi-word extension for longest plausible term)
        local max_window = Options.anki_local_fuzzy_window + (Options.anki_split_search_window or 15)
        local t_lo = sub_start - max_window
        local t_hi = sub_end   + max_window
        local sorted = FSM.ANKI_HIGHLIGHTS_SORTED
        -- Binary search: find first index where sorted[i].time >= t_lo
        local lo, hi = 1, #sorted
        local first = #sorted + 1
        while lo <= hi do
            local mid = math.floor((lo + hi) / 2)
            if sorted[mid].time >= t_lo then first = mid; hi = mid - 1
            else lo = mid + 1 end
        end
        candidates = {}
        for k = first, #sorted do
            if sorted[k].time > t_hi then break end
            table.insert(candidates, FSM.ANKI_HIGHLIGHTS[sorted[k].idx])
        end
    else
        candidates = FSM.ANKI_HIGHLIGHTS
    end

    for _, data in ipairs(candidates) do
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

            local t_center = data.__cached_anchor_sub
            if not t_center or data.__cached_time ~= data.time then
                t_center = get_center_index(subs, data.time)
                data.__cached_anchor_sub = t_center
                data.__cached_time = data.time
            end

            local in_span = false
            if t_center ~= -1 and data.__min_l and data.__max_l then
                local s_idx = t_center + data.__min_l
                local e_idx = t_center + data.__max_l
                if sub_idx >= s_idx and sub_idx <= e_idx then
                    in_span = true
                end
            end

            if Options.anki_global_highlight or in_span or in_window then
                -- Footprint Check for intersection depth
                local is_in_footprint = false
                if t_center ~= -1 and data.__min_l then
                    local t_start = (t_center + data.__min_l) * 1000 + data.__min_w
                    local t_end = (t_center + data.__max_l) * 1000 + data.__max_w
                    local t_total = sub_idx * 1000 + target_l_idx
                    if t_total >= t_start and t_total <= t_end then
                        is_in_footprint = true
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

                                    -- Requirement 60: Detect if words are sequential (contiguous) in the text stream
                                    local is_contiguous = true
                                    local last_c = -1
                                    for _, c_idx in ipairs(best_tuple) do
                                        if last_c ~= -1 and c_idx ~= last_c + 1 then
                                            is_contiguous = false
                                            break
                                        end
                                        last_c = c_idx
                                    end
                                    valid_set.is_contiguous = is_contiguous
                                end
                            end
                            subs[sub_idx].__split_valid_indices[term_key] = valid_set
                        end
                        
                        if valid_set then
                            if valid_set.indices[sub_idx .. "-" .. token_idx] then
                                match_found = true
                                term_is_split = not valid_set.is_contiguous
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
                    -- Verified split matches contribute to purple_depth for mixed color scaling
                    purple_depth = purple_depth + 1
                else 
                    orange_stack = orange_stack + 1
                    -- Contiguous matches only contribute to purple_depth (shadow depth)
                    -- if they overlap with something else, but we increment it here
                    -- if there was a verified footprint shadow.
                    if is_in_footprint then
                        purple_depth = purple_depth + 1
                    end
                end
                matched_terms[term_key] = true
                has_phrase = has_phrase or (#term_clean > 1)
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
    
    print(string.format("[kardenwort] Search Pivot: %.1f | Term: '%s' | Text Len: %d", center, selected_term, #full_line))
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
        

    else

    end
    if first_idx then
        Diagnostic.trace(string.format("  - Span Detected: Word %d to %d", first_idx, last_idx))
    else

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
        Diagnostic.trace(string.format("  - Span (%d) >= limit (%d), cropping to span+pad [%d..%d]", span, limit, crop_start, crop_end))
        local f_byte = (crop_start == 1) and 1 or nil
        local l_byte = (crop_end == #words) and #sentence or nil
        local curr = 1
        for i = 1, crop_end do
            local s, e = sentence:find(words[i], curr, true)
            if s then
                if i == crop_start then f_byte = s end
                if i == crop_end then l_byte = e end
                curr = e + 1
            end
        end
        return sentence:sub(f_byte or 1, l_byte or #sentence):match("^%s*(.-)%s*$")
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
    
    Diagnostic.trace(string.format("  - Viewport: %d to %d (Center: %d)", context_start, context_end, center_idx))
    
    local f_byte = (context_start == 1) and 1 or nil
    local l_byte = (context_end == #words) and #sentence or nil
    local curr = 1
    for i = 1, context_end do
        local s, e = sentence:find(words[i], curr, true)
        if s then
            if i == context_start then f_byte = s end
            if i == context_end then l_byte = e end
            curr = e + 1
        end
    end
    return sentence:sub(f_byte or 1, l_byte or #sentence):match("^%s*(.-)%s*$")
end



local function get_tsv_path()
    if Options.anki_record_file and Options.anki_record_file ~= "" then return Options.anki_record_file end
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
        show_osd("Set kardenwort-record_editor in mpv.conf")
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
-- Centralized cache invalidation for all rendering layers.
-- INVARIANT: DRUM_DRAW_CACHE and DW_DRAW_CACHE are captured by upvalue.
-- They MUST be defined at module scope before this function is called at runtime,
-- otherwise the cache flushing will silently fail.
local function flush_rendering_caches()
    FSM.ANKI_VERSION = (FSM.ANKI_VERSION or 0) + 1
    FSM.LAYOUT_VERSION = (FSM.LAYOUT_VERSION or 0) + 1
    
    -- Invalidate top-level ASS result caches
    FSM.DW_LAYOUT_CACHE = nil
    
    -- Reset sentinel fields to force mismatch in draw high-level caches
    if DRUM_DRAW_CACHE then 
        DRUM_DRAW_CACHE.center_idx = -1 
        DRUM_DRAW_CACHE.is_drum = false
    end
    
    if DW_DRAW_CACHE then 
        DW_DRAW_CACHE.view_center = -1 
    end
    
    if DW_TOOLTIP_DRAW_CACHE then
        DW_TOOLTIP_DRAW_CACHE.target_idx = -1
        DW_TOOLTIP_DRAW_CACHE.osd_y = -1
        DW_TOOLTIP_DRAW_CACHE.version = -1
        DW_TOOLTIP_DRAW_CACHE.cl = -1
        DW_TOOLTIP_DRAW_CACHE.cw = -1
        DW_TOOLTIP_DRAW_CACHE.av = -1
        DW_TOOLTIP_DRAW_CACHE.result = ""
        DW_TOOLTIP_DRAW_CACHE.hit_zones = nil
    end
    dw_tooltip_osd.data = ""
end

local function invalidate_dw_tooltip_cache()
    if not DW_TOOLTIP_DRAW_CACHE then return end
    DW_TOOLTIP_DRAW_CACHE.target_idx = -1
    DW_TOOLTIP_DRAW_CACHE.osd_y = -1
    DW_TOOLTIP_DRAW_CACHE.version = -1
    DW_TOOLTIP_DRAW_CACHE.cl = -1
    DW_TOOLTIP_DRAW_CACHE.cw = -1
    DW_TOOLTIP_DRAW_CACHE.av = -1
    DW_TOOLTIP_DRAW_CACHE.result = ""
    DW_TOOLTIP_DRAW_CACHE.hit_zones = nil
end

local function clear_tooltip_overlay(reason)
    if reason then
        Diagnostic.debug("TOOLTIP CLEAR: " .. reason)
    end
    FSM.DW_TOOLTIP_LINE = -1
    FSM.DW_TOOLTIP_HIT_ZONES = nil
    FSM.DW_TOOLTIP_LOCKED_LINE = -1
    invalidate_dw_tooltip_cache()
    if dw_tooltip_osd and dw_tooltip_osd.data ~= "" then
        dw_tooltip_osd.data = ""
        dw_tooltip_osd:update()
    end
end

local function is_osd_tooltip_mode_eligible()
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local srt_active = (FSM.DRUM == "OFF" and use_osd_for_srt)

    return (FSM.DRUM == "ON" or srt_active)
        and FSM.DRUM_WINDOW == "OFF"
        and FSM.native_sub_vis
        and not FSM.MEDIA_STATE:match("ASS")
        and Options.osd_interactivity
end

local function get_tooltip_line_y(line_idx, fallback_y)
    if not line_idx or line_idx == -1 then return nil end
    if FSM.DRUM_WINDOW ~= "OFF" then
        return FSM.DW_LINE_Y_MAP[line_idx] or fallback_y
    end
    for _, zone in ipairs(FSM.DRUM_HIT_ZONES or {}) do
        if zone.sub_idx == line_idx and zone.is_pri then
            return zone.y_top
        end
    end
    return fallback_y
end


local function load_anki_tsv(force, quiet)
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

    -- Use utils.read_file for robust UTF-8 path handling on Windows
    -- Use safe_read_file for robust path handling and version compatibility
    local content = safe_read_file(tsv_path)
    if not content then
        FSM.ANKI_HIGHLIGHTS = {}
        Diagnostic.info("TSV file missing - attempting auto-creation: " .. tostring(tsv_path))
        
        -- Build header from actual config fields; fall back to generic defaults
        local header_line
        if #config.fields > 0 then
            header_line = table.concat(config.fields, "\t")
        else
            header_line = "Term\tSentence\tTime"
        end

        local deck_col = -1
        for i, fld in ipairs(config.fields) do
            local src = config.mapping[fld] or config.mapping_word[fld] or config.mapping_sentence[fld]
            if src == "deck_name" then deck_col = i; break end
        end

        local f = io.open(tsv_path, "w")
        if f then
            if deck_col > 0 then f:write(string.format("#deck column:%d\n", deck_col)) end
            f:write(header_line .. "\n")
            f:close()
            content = safe_read_file(tsv_path)
            if not content then 
                Diagnostic.error("TSV creation failed - could not read back file")
                return 
            end
        else
            Diagnostic.error("TSV creation failed - could not open for writing")
            return 
        end
    end


    local new_highlights = {}

    for line in (content .. "\n"):gmatch("(.-)\r?\n") do
        pcall(function()
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
                    
                    local is_header = (term_header_name and t == term_header_name)
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
        end)
    end
    
    FSM.ANKI_HIGHLIGHTS = new_highlights

    -- Build time-sorted index for O(log H) binary-search window lookups.
    -- Each entry is {time, idx} where idx is the position in ANKI_HIGHLIGHTS.
    local sorted = {}
    for i, h in ipairs(new_highlights) do
        table.insert(sorted, { time = h.time, idx = i })
    end
    table.sort(sorted, function(a, b) return a.time < b.time end)
    FSM.ANKI_HIGHLIGHTS_SORTED = sorted

    -- Flush stale __split_valid_indices caches: term set may have changed.
    if Tracks.pri.subs then
        for _, sub in ipairs(Tracks.pri.subs) do sub.__split_valid_indices = nil end
    end
    if Tracks.sec.subs then
        for _, sub in ipairs(Tracks.sec.subs) do sub.__split_valid_indices = nil end
    end
    
    FSM.ANKI_DB_MTIME = info and info.mtime or 0
    FSM.ANKI_DB_SIZE = info and info.size or 0

    flush_rendering_caches()
    local msg_text = string.format("TSV Loaded: %d highlights (mtime=%s, size=%s)", #new_highlights, tostring(FSM.ANKI_DB_MTIME), tostring(FSM.ANKI_DB_SIZE))
    local dedupe_key = "tsv-load-" .. tostring(FSM.ANKI_DB_MTIME) .. "-" .. tostring(FSM.ANKI_DB_SIZE)
    
    if quiet then

    else
        Diagnostic.info(msg_text, dedupe_key)
    end
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
        if next(config.mapping_sentence) then 
            mapping = config.mapping_sentence 
            if #fields == 0 then fields = config.ordered_sentence end
        end
    else
        if next(config.mapping_word) then 
            mapping = config.mapping_word 
            if #fields == 0 then fields = config.ordered_word end
        end
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
    local new_h_idx = #FSM.ANKI_HIGHLIGHTS

    -- Maintain the time-sorted index for binary-search window lookups.
    -- New highlights are typically near current playback time, so scan from end.
    if FSM.ANKI_HIGHLIGHTS_SORTED then
        local sorted = FSM.ANKI_HIGHLIGHTS_SORTED
        local ins_pos = #sorted + 1
        for j = #sorted, 1, -1 do
            if sorted[j].time <= time_pos then break end
            ins_pos = j
        end
        table.insert(sorted, ins_pos, { time = time_pos, idx = new_h_idx })
    end
    
    flush_rendering_caches()
    
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
    if Tracks.sec.path ~= old_sec_path then
        if old_sec_path and Tracks.sec.subs and #Tracks.sec.subs > 0 then
            FSM.DW_TOOLTIP_SEC_SUBS = Tracks.sec.subs
            FSM.DW_TOOLTIP_SEC_PATH = old_sec_path
        end
        Tracks.sec.subs = {}
    end

    -- Load subtitles for logic memory if necessary (always eager to support global navigation)
    if Tracks.pri.path and #Tracks.pri.subs == 0 then
        Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
    end
    if Tracks.sec.path and #Tracks.sec.subs == 0 then
        Tracks.sec.subs = load_sub(Tracks.sec.path, Tracks.sec.is_ass)
        if Tracks.sec.subs and #Tracks.sec.subs > 0 then
            FSM.DW_TOOLTIP_SEC_SUBS = Tracks.sec.subs
            FSM.DW_TOOLTIP_SEC_PATH = Tracks.sec.path
        end
    end

    -- Tooltip cache is empty and secondary track is disabled: pre-load the first eligible external
    -- subtitle as tooltip source so Drum Mode tooltip works without enabling secondary subs first.
    if Tracks.sec.id == 0 and #FSM.DW_TOOLTIP_SEC_SUBS == 0 then
        for _, t in ipairs(track_list) do
            if t.type == "sub" and t.external and t["external-filename"] and t.id ~= Tracks.pri.id then
                local cpath = t["external-filename"]
                local cis_ass = cpath:lower():match("%.ass$") or cpath:lower():match("%.ssa$") or
                                (t.codec == "ass" or t.codec == "ssa")
                local loaded = load_sub(cpath, cis_ass)
                if loaded and #loaded > 0 then
                    FSM.DW_TOOLTIP_SEC_SUBS = loaded
                    FSM.DW_TOOLTIP_SEC_PATH = cpath
                end
                break
            end
        end
    end

    flush_rendering_caches()

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

    -- ASS gatekeeping: disable custom OSD modes in the same transition cycle.
    if FSM.MEDIA_STATE:match("ASS") then
        local had_drum = (FSM.DRUM == "ON")
        local had_dw = (FSM.DRUM_WINDOW ~= "OFF")
        FSM.DRUM = "OFF"
        FSM.DRUM_WINDOW = "OFF"
        FSM.DW_TOOLTIP_FORCE = false

        -- Restore native subtitle presentation from FSM desired state.
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)

        drum_osd.data = ""
        drum_osd:update()
        dw_osd.data = ""
        dw_osd:update()
        clear_tooltip_overlay("ass-gatekeeping")
        update_interactive_bindings()

        if had_drum or had_dw then
            show_osd("Custom OSD: AUTO-DISABLED (ASS Track Loaded)", Options.osd_duration + 1.0)
        end
    end
end

-- =========================================================================
-- HIGHLIGHT RENDERING UTILS
-- =========================================================================

local function is_ignorable_for_semantic_pass(text)
    if not text then return true end
    if text:match("^%s*$") then return true end -- Whitespace
    if text:match("^{") then return true end    -- ASS Tag
    if text == "\\N" or text == "\\n" or text == "\\h" then return true end -- Line breaks
    return false
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
    if l == p1_l and w < p1_w - L_EPSILON then return false end
    if l == p2_l and w > p2_w + L_EPSILON then return false end
    return true
end

local function populate_token_meta(subs, sub_idx, tokens, base_color, t_pos, entry, force_plain, h_color, ctrl_color)
    local token_meta = {}
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    
    -- Fallbacks (Task 2.2)
    h_color = h_color or Options.dw_highlight_color
    ctrl_color = ctrl_color or Options.dw_ctrl_select_color
    
    for j, t in ipairs(tokens) do
        local l_idx = t.logical_idx or (entry and entry.visual_to_logical[j])
        local meta = { text = t.text, color = base_color, is_word = t.is_word, is_phrase = false, priority = 0 }
        
        if l_idx and not force_plain then
            -- Level 1: Persistent Selection (Pink)
            local line_set = FSM.DW_CTRL_PENDING_SET[sub_idx]
            if line_set and line_set[l_idx] then
                meta.color = ctrl_color
                meta.priority = 1
            end

            -- Level 2: Selection/Hover (Yellow)
            if meta.priority == 0 then
                local selected = is_inside_dw_selection(sub_idx, l_idx)
                local is_focus_point = (sub_idx == cl and logical_cmp(l_idx, cw))
                if selected or is_focus_point then
                    meta.color = h_color
                    meta.priority = 2
                end
            end

            -- Level 3: Database Highlights (Orange/Purple)
            if meta.priority == 0 then
                local h_cache = t.highlight_cache
                local orange_stack, purple_stack, is_phrase, matching_terms, purple_depth
                
                if h_cache and h_cache.version == FSM.ANKI_VERSION then
                    orange_stack = h_cache.orange_stack
                    purple_stack = h_cache.purple_stack
                    is_phrase = h_cache.is_phrase
                    matching_terms = h_cache.matching_terms
                    purple_depth = h_cache.purple_depth
                else
                    orange_stack, purple_stack, is_phrase, matching_terms, purple_depth = calculate_highlight_stack(subs, sub_idx, j, t_pos)
                    t.highlight_cache = {
                        version = FSM.ANKI_VERSION,
                        orange_stack = orange_stack,
                        purple_stack = purple_stack,
                        is_phrase = is_phrase,
                        matching_terms = matching_terms,
                        purple_depth = purple_depth
                    }
                end
                
                meta.purple_depth = purple_depth
                local h_color = base_color
                
                if orange_stack > 0 and purple_stack > 0 then
                    local mix_depth = math.min((orange_stack + (purple_depth or 1)) - 1, 3)
                    if mix_depth == 1 then h_color = Options.anki_mix_depth_1 or "4A4AD3"
                    elseif mix_depth == 2 then h_color = Options.anki_mix_depth_2 or "3636A8"
                    elseif mix_depth >= 3 then h_color = Options.anki_mix_depth_3 or "151578" end
                elseif orange_stack > 0 then
                    local o_depth = math.min(orange_stack, 3)
                    if o_depth == 1 then h_color = Options.anki_highlight_depth_1
                    elseif o_depth == 2 then h_color = Options.anki_highlight_depth_2
                    else h_color = Options.anki_highlight_depth_3 end
                elseif purple_stack > 0 then
                    local p_depth = math.min(purple_stack, 3)
                    if p_depth == 1 then h_color = Options.anki_split_depth_1 or "B088FF"
                    elseif p_depth == 2 then h_color = Options.anki_split_depth_2 or "9674D9"
                    else h_color = Options.anki_split_depth_3 or "7C60B3" end
                end

                if h_color ~= base_color then
                    meta.color = h_color
                    meta.is_phrase = is_phrase
                    meta.matching_terms = matching_terms
                    meta.priority = 3
                end
            end
        end
        token_meta[j] = meta
    end
    return token_meta
end

local function format_highlighted_word(word, h_color, base_color, is_phrase, bold_state, use_1c, force_bold, is_manual, bg_color, bg_alpha, border_size)
    if type(word) == "table" then word = word.text end
    if not word then return "" end
    
    local c_tag = use_1c and "1c" or "c"
    local is_bold = (force_bold ~= nil) and force_bold or Options.anki_highlight_bold
    local b_on = string.format("{\\b%s}", is_bold and "1" or "0")
    local b_off = string.format("{\\b%s}", bold_state or "0")
    
    if (h_color == base_color) then return word end

    -- Keep highlight geometry identical to baseline text geometry to avoid
    -- frame expansion when selection colors are active.
    bg_color = bg_color or "000000"
    bg_alpha = bg_alpha or "00"
    border_size = border_size or Options.dw_border_size
    local h_tags = string.format("{\\%s&H%s&\\3c&H%s&\\4c&H%s&\\3a&H%s&\\4a&H%s&\\bord%g}", c_tag, h_color, bg_color, bg_color, bg_alpha, bg_alpha, border_size)
    local r_tags = string.format("{\\%s&H%s&\\3c&H%s&\\4c&H%s&\\3a&H%s&\\4a&H%s&\\bord%g}", c_tag, base_color, bg_color, bg_color, bg_alpha, bg_alpha, border_size)

    if is_phrase or is_manual then
        -- Full highlighting for phrases or manual user focus (Gold/Pink)
        -- Enforce "Premium" regular weight for manual selections
        return string.format("{\\b0}%s%s%s{\\b%s}", h_tags, word, r_tags, bold_state or "0")
    else
        -- Surgical highlighting for automated database matches (Surgical Punctuation)
        local pre = word:match("^[%p%s]*")
        local suf = word:match("[%p%s]*$")
        local mid = ""
        if #pre < #word then
            mid = word:sub(#pre + 1, #word - #suf)
        end
        if mid ~= "" then
            return string.format("%s%s%s%s%s%s%s", pre, b_on, h_tags, mid, b_off, r_tags, suf)
        else
            -- Professional look: single-word database matches keep their surrounding punctuation uncolored
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


local function calculate_sub_gap(prefix, font_size, lh_mul, vsp)
    local b_gap_mul = Options[prefix .. "_block_gap_mul"] or 0
    local d_gap = Options[prefix .. "_double_gap"]
    
    if d_gap then
        return (font_size * lh_mul) + (font_size * b_gap_mul) + vsp
    else
        return 0
    end
end

local function wrap_tokens(tokens, max_w, font_size, font_name, keep_spaces)
    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    local space_w = dw_get_str_width(" ", font_size, font_name)
    
    for j, t in ipairs(tokens) do
        local ww = dw_get_str_width(t.text, font_size, font_name)
        local space = (#cur_indices > 0 and not keep_spaces) and space_w or 0
        
        -- Force break on explicit newline
        local has_newline = t.text:find("\n") ~= nil
        
        if (cur_w + space + ww > max_w and #cur_indices > 0) or has_newline then
            if #cur_indices > 0 then
                table.insert(vlines, cur_indices)
                cur_indices = {}
                cur_w = 0
            end
            
            if not has_newline or t.text:gsub("\n", "") ~= "" then
                -- If it's not JUST a newline, or we want to keep it as a word
                table.insert(cur_indices, j)
                cur_w = ww
            end
        else
            table.insert(cur_indices, j)
            cur_w = cur_w + space + ww
        end
    end
    if #cur_indices > 0 then table.insert(vlines, cur_indices) end
    return vlines
end

local function calculate_osd_line_meta(text, sub_idx, font_size, font_name, line_height_mul, vsp)
    local tokens = build_word_list_internal(text, Options.dw_original_spacing)
    local max_text_w = 1860
    local vline_indices = wrap_tokens(tokens, max_text_w, font_size, font_name, Options.dw_original_spacing)
    
    -- Synthesize a vline for empty text to reserve slot height (fixes regression)
    if #vline_indices == 0 then
        vline_indices = {{}}
    end

    local space_w = dw_get_str_width(" ", font_size, font_name)
    
    local lines = {}
    local total_h = 0
    local max_w = 0
    
    for i, vl_idx_list in ipairs(vline_indices) do
        local words = {}
        local line_w = 0
        for pos, j in ipairs(vl_idx_list) do
            local t = tokens[j]
            local ww = dw_get_str_width(t.text, font_size, font_name)
            local space = (pos > 1 and not Options.dw_original_spacing) and space_w or 0
            
            if t.is_word and t.logical_idx then
                table.insert(words, {
                    logical_idx = t.logical_idx,
                    x_offset = line_w + space, -- Relative to start of visual line
                    width = ww,
                    text = t.text
                })
            end
            line_w = line_w + space + ww
        end
        
        local h = (font_size * line_height_mul) + vsp
        table.insert(lines, {
            words = words,
            total_width = line_w,
            height = h,
            y_offset = total_h,
            token_indices = vl_idx_list
        })
        total_h = total_h + h
        max_w = math.max(max_w, line_w)
    end
    
    return {
        sub_idx = sub_idx,
        vlines = lines,
        total_width = max_w,
        total_height = total_h,
        tokens = tokens, -- Keep tokens for rendering
        size = font_size -- Store for inter-subtitle gap calculation
    }
end

-- Result cache for draw_drum: skip full ASS rebuild when state is unchanged.
-- Mirrors the DW_DRAW_CACHE pattern used by draw_dw().
DRUM_DRAW_CACHE = {
    subs_ptr = nil, center_idx = -1, highlight_count = 0, is_drum = false,
    al = -1, aw = -1, cl = -1, cw = -1,
    pending_version = 0, layout_version = 0, result = "",
    hit_zones = nil -- Cached geometry
}

local function draw_drum(subs, view_center, active_idx, y_pos_percent, time_pos, font_size, hit_zones, force_plain, is_pri)
    if view_center == -1 then return "" end

    -- Result cache: skip rebuild if nothing has changed since last call.
    if DRUM_DRAW_CACHE.subs_ptr == subs and
       DRUM_DRAW_CACHE.view_center     == view_center and
       DRUM_DRAW_CACHE.active_idx      == active_idx and
       DRUM_DRAW_CACHE.is_drum         == (FSM.DRUM == "ON") and
       DRUM_DRAW_CACHE.highlight_count == #FSM.ANKI_HIGHLIGHTS and
       DRUM_DRAW_CACHE.layout_version   == FSM.LAYOUT_VERSION and
       DRUM_DRAW_CACHE.al              == FSM.DW_ANCHOR_LINE and
       DRUM_DRAW_CACHE.aw              == FSM.DW_ANCHOR_WORD and
       DRUM_DRAW_CACHE.cl              == FSM.DW_CURSOR_LINE and
       DRUM_DRAW_CACHE.cw              == FSM.DW_CURSOR_WORD and
       DRUM_DRAW_CACHE.pending_version == (FSM.DW_CTRL_PENDING_VERSION or 0) then
        
        -- If hit_zones was requested and we have it cached, populate it.
        if hit_zones and DRUM_DRAW_CACHE.hit_zones then
            for k, v in ipairs(DRUM_DRAW_CACHE.hit_zones) do hit_zones[k] = v end
        end
        return DRUM_DRAW_CACHE.result
    end

    local is_drum = (FSM.DRUM == "ON")
    local context_lines = is_drum and Options.drum_context_lines or 0
    local half = context_lines
    local start_idx = math.max(1, view_center - half)
    local end_idx = math.min(#subs, view_center + half)
    
    -- Re-adjust to maintain window size if possible
    if end_idx - start_idx < 2 * half then
        if start_idx == 1 then
            end_idx = math.min(#subs, start_idx + 2 * half)
        elseif end_idx == #subs then
            start_idx = math.max(1, end_idx - 2 * half)
        end
    end

    local is_top = (y_pos_percent < 50)
    local y_pixel = y_pos_percent * 1080 / 100
    
    local is_drum_mode = (FSM.DRUM == "ON")
    local prefix = is_drum_mode and "drum" or "srt"
    local font_name = is_drum_mode and (Options.drum_font_name ~= "" and Options.drum_font_name or mp.get_property("sub-font", "Inter"))
                                   or (Options.srt_font_name ~= "" and Options.srt_font_name or mp.get_property("sub-font", "Inter"))
    local lh_mul = is_drum_mode and Options.drum_line_height_mul or Options.srt_line_height_mul
    local vsp = is_drum_mode and Options.drum_vsp or Options.srt_vsp
    local d_gap = Options[prefix .. "_double_gap"]
    local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0

    local sub_metas = {}
    local total_h = 0
    
    for i = start_idx, end_idx do
        local is_active = (i == active_idx)
        local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
        local m = calculate_osd_line_meta(subs[i].text, i, size, font_name, lh_mul, vsp)
        
        -- Pass 1: Global Highlight Pre-Pass
        local base_color = is_drum_mode and (is_active and Options.drum_active_color or Options.drum_context_color)
                                        or (is_active and Options.srt_active_color or Options.srt_context_color)
        
        local h_color = is_drum_mode and (is_pri and Options.drum_pri_highlight_color or Options.drum_sec_highlight_color)
                                     or (is_pri and Options.srt_pri_highlight_color or Options.srt_sec_highlight_color)
        local c_color = is_drum_mode and (is_pri and Options.drum_pri_ctrl_select_color or Options.drum_sec_ctrl_select_color)
                                     or (is_pri and Options.srt_pri_ctrl_select_color or Options.srt_sec_ctrl_select_color)
        local h_bold = is_drum_mode and (is_pri and Options.drum_pri_highlight_bold or Options.drum_sec_highlight_bold)
                                    or (is_pri and Options.srt_pri_highlight_bold or Options.srt_sec_highlight_bold)

        m.token_meta = populate_token_meta(subs, i, m.tokens, base_color, subs[i].start_time, nil, force_plain, h_color, c_color)
        m.h_bold = h_bold
        
        table.insert(sub_metas, m)
        total_h = total_h + m.total_height
        if i < end_idx then
            total_h = total_h + calculate_sub_gap(prefix, m.size, lh_mul, vsp) + adj
        end
    end

    local y_start = y_pixel
    if not is_top then y_start = y_pixel - total_h end
    
    local cur_y = y_start
    for _, m in ipairs(sub_metas) do
        if hit_zones and Options.osd_interactivity then
            for _, vl in ipairs(m.vlines) do
                vl.y_top = cur_y + vl.y_offset
                vl.y_bottom = vl.y_top + vl.height
                vl.x_start = 960 - vl.total_width / 2
                vl.sub_idx = m.sub_idx -- For hit-zone tracking
                vl.is_pri = is_pri
                table.insert(hit_zones, vl)
            end
        end
        cur_y = cur_y + m.total_height
        if m.sub_idx < end_idx then
            cur_y = cur_y + calculate_sub_gap(prefix, m.size, lh_mul, vsp) + adj
        end
    end

    local bg_color = is_drum and Options.drum_bg_color or Options.srt_bg_color
    local bg_opacity = is_drum and Options.drum_bg_opacity or Options.srt_bg_opacity
    local bord = is_drum and Options.drum_border_size or Options.srt_border_size
    local shad = is_drum and Options.drum_shadow_offset or Options.srt_shadow_offset

    -- Rendering logic
    local function format_sub_wrapped(meta, is_active, t_pos)
        local tokens = meta.tokens
        local vlines = meta.vlines
        local token_meta = meta.token_meta
        if #tokens == 0 or not token_meta then return "" end

        local base_color = is_drum and (is_active and Options.drum_active_color or Options.drum_context_color)
                                    or (is_active and Options.srt_active_color or Options.srt_context_color)
        local opacity = calculate_ass_alpha(is_drum and (is_active and Options.drum_active_opacity or Options.drum_context_opacity)
                                                      or (is_active and Options.srt_active_opacity or Options.srt_context_opacity))
        local f_bold = is_drum and Options.drum_font_bold or Options.srt_font_bold
        local bold_state = (is_active and (is_drum and Options.drum_active_bold or f_bold) 
                                      or (is_drum and Options.drum_context_bold or f_bold)) and "1" or "0"
        local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)

        local line_strings = {}
        for _, vl in ipairs(vlines) do
            local formatted_parts = {}
            for _, j in ipairs(vl.token_indices) do
                local meta_item = token_meta[j]
                if meta_item.priority >= 1 or (meta_item.priority == 0 and meta_item.is_phrase) then
                    local final_bold = (meta_item.priority == 3) and Options.anki_highlight_bold or meta.h_bold
                    local is_man = (meta_item.priority == 1 or meta_item.priority == 2)
                    local bg_alpha = calculate_ass_alpha(is_drum and Options.drum_bg_opacity or Options.srt_bg_opacity)
                    table.insert(formatted_parts, format_highlighted_word({text = meta_item.text}, meta_item.color, base_color, meta_item.is_phrase, bold_state, true, final_bold, is_man, is_drum and Options.drum_bg_color or Options.srt_bg_color, bg_alpha, bord))
                else
                    table.insert(formatted_parts, meta_item.text)
                end
            end
            local line_text = ""
            if Options.dw_original_spacing then
                line_text = table.concat(formatted_parts, "")
            else
                line_text = compose_term_smart(formatted_parts)
            end
            table.insert(line_strings, (line_text:gsub("\n", "")))
        end

        local result_text = table.concat(line_strings, "\\N")
        return string.format("{\\fn%s}{\\1a&H%s&}{\\b%s}{\\1c&H%s&}{\\fs%d}%s", 
            font_name, opacity, bold_state, base_color, size, result_text)
    end

    local all_text = ""
    local vsp_tag = vsp ~= 0 and string.format("{\\vsp%g}", vsp) or ""
    
    for i, m in ipairs(sub_metas) do
        local line_text = format_sub_wrapped(m, m.sub_idx == active_idx, subs[m.sub_idx].start_time)
        if i == 1 then
            all_text = line_text
        else
            local prev_is_active = (sub_metas[i-1].sub_idx == active_idx)
            local line_fs = font_size * (prev_is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
            local vsp_extra = d_gap and (line_fs * Options[prefix .. "_block_gap_mul"] / 2) or 0
            local separator = string.format("{\\vsp%g}%s{\\vsp%g}", vsp + vsp_extra + adj, d_gap and "\\N\\N" or "\\N", vsp)
            all_text = all_text .. separator .. line_text
        end
    end

    local style_block = string.format("{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}%s", 
        bord, shad, bg_color, bg_color, calculate_ass_alpha(bg_opacity), calculate_ass_alpha(bg_opacity), vsp_tag)

    local ass = ""
    if is_top then
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    else
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    end

    -- Update result cache before returning
    DRUM_DRAW_CACHE.subs_ptr        = subs
    DRUM_DRAW_CACHE.view_center     = view_center
    DRUM_DRAW_CACHE.active_idx      = active_idx
    DRUM_DRAW_CACHE.is_drum         = (FSM.DRUM == "ON")
    DRUM_DRAW_CACHE.highlight_count = #FSM.ANKI_HIGHLIGHTS
    DRUM_DRAW_CACHE.layout_version  = FSM.LAYOUT_VERSION
    DRUM_DRAW_CACHE.al              = FSM.DW_ANCHOR_LINE
    DRUM_DRAW_CACHE.aw              = FSM.DW_ANCHOR_WORD
    DRUM_DRAW_CACHE.cl              = FSM.DW_CURSOR_LINE
    DRUM_DRAW_CACHE.cw              = FSM.DW_CURSOR_WORD
    DRUM_DRAW_CACHE.pending_version = FSM.DW_CTRL_PENDING_VERSION or 0
    DRUM_DRAW_CACHE.result          = ass
    
    -- If hit_zones was populated during this draw, cache it too.
    if hit_zones then
        DRUM_DRAW_CACHE.hit_zones = {}
        for k, v in ipairs(hit_zones) do DRUM_DRAW_CACHE.hit_zones[k] = v end
    else
        DRUM_DRAW_CACHE.hit_zones = nil
    end

    return ass
end


-- Unified layout engine: wraps subtitle words into visual lines
local function dw_build_layout(subs, view_center)
    -- Performance Cache Check: Re-use layout if viewport and subs haven't changed.
    -- This drastically reduces CPU load during mouse interaction and OSD updates.
    if FSM.DW_LAYOUT_CACHE and 
       FSM.DW_LAYOUT_CACHE.view_center == view_center and 
       FSM.DW_LAYOUT_CACHE.subs_ptr == subs and
       FSM.DW_LAYOUT_CACHE.layout_version == FSM.LAYOUT_VERSION then
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
        local s = subs[i]
        local entry
        
        -- Sub-level Layout Cache: Reuse wrapped lines if track/options haven't changed.
        -- NOTE: This cache is intentionally session-lived and accumulates across all visited
        -- subtitles. It is evicted only via flush_rendering_caches() or track reload.
        if s.layout_cache and s.layout_cache.version == FSM.LAYOUT_VERSION then
            entry = s.layout_cache.entry
            -- Compatibility guard:
            -- ensure_sub_layout() may cache a reduced entry for navigation that lacks
            -- draw-time fields (e.g. height/sub_idx). Rebuild full draw entry when needed.
            if not entry
                or type(entry.height) ~= "number"
                or not entry.vlines
                or type(entry.sub_idx) ~= "number"
                or not entry.logical_words
                or not entry.visual_to_logical
            then
                entry = nil
            end
        end

        if not entry then
            local tokens = get_sub_tokens(s)
            if #tokens == 0 then tokens = {{text=""}} end

            local logical_words = {}
            local visual_to_logical = {}
            local logical_to_visual = {}
            
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
            entry = {
                sub_idx = i,
                words = tokens,
                logical_words = logical_words,
                visual_to_logical = visual_to_logical,
                logical_to_visual = logical_to_visual,
                height = entry_h,
                vlines = vlines
            }
            
            -- Memoize on the subtitle object
            s.layout_cache = {
                version = FSM.LAYOUT_VERSION,
                entry = entry
            }
        end
        
        table.insert(layout, entry)
        total_height = total_height + entry.height
        if i < end_idx then total_height = total_height + sub_gap end
    end

    -- Store in cache before returning
    FSM.DW_LAYOUT_CACHE = {
        view_center = view_center,
        subs_ptr = subs,
        layout_version = FSM.LAYOUT_VERSION,
        layout = layout,
        total_height = total_height
    }

    return layout, total_height
end

-- draw_dw: view_center = which line is in the center of the viewport
--          active_idx = which line is currently playing (colored blue, may be off-screen)
DW_DRAW_CACHE = {
    view_center = -1, active_idx = -1, highlight_count = 0,
    subs_ptr = nil, layout_version = 0,
    cl = -1, cw = -1, al = -1, aw = -1,
    pending_version = 0, result = ""
}

local function draw_dw(subs, view_center, active_idx)
    if not subs or #subs == 0 then return "" end
    
    -- High-level Result Cache: Skip entire rendering if state is identical.
    -- FSM.DW_CTRL_PENDING_VERSION is incremented whenever the Pink set changes.
    if DW_DRAW_CACHE.view_center    == view_center and
       DW_DRAW_CACHE.active_idx     == active_idx and
       DW_DRAW_CACHE.subs_ptr       == subs and
       DW_DRAW_CACHE.highlight_count == #FSM.ANKI_HIGHLIGHTS and
       DW_DRAW_CACHE.layout_version  == FSM.LAYOUT_VERSION and
       DW_DRAW_CACHE.cl             == FSM.DW_CURSOR_LINE and
       DW_DRAW_CACHE.cw             == FSM.DW_CURSOR_WORD and
       DW_DRAW_CACHE.al             == FSM.DW_ANCHOR_LINE and
       DW_DRAW_CACHE.aw             == FSM.DW_ANCHOR_WORD and
       DW_DRAW_CACHE.pending_version == (FSM.DW_CTRL_PENDING_VERSION or 0) then
        
        return DW_DRAW_CACHE.result
    end

    local ass = ""
    local bg_alpha = calculate_ass_alpha(Options.dw_bg_opacity)
    local layout, total_height = dw_build_layout(subs, view_center)
    local lh_mul = Options.dw_line_height_mul
    local current_y = 540 - (total_height / 2)
    FSM.DW_LINE_Y_MAP = {}
    
    -- Selection range
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD

    -- Pass 1: Global Highlight Pre-Pass
    for layout_i, entry in ipairs(layout) do
        local i = entry.sub_idx
        local is_active = (i == active_idx)
        local base_color = is_active and Options.dw_active_color or Options.dw_context_color
        entry.token_meta = populate_token_meta(subs, i, entry.words, base_color, subs[i].start_time, entry, not Options.dw_pri_highlighting, Options.dw_highlight_color, Options.dw_ctrl_select_color)
    end



    -- Text Block mapping
    local lines_ass = {}
    for layout_i, entry in ipairs(layout) do
        local i = entry.sub_idx
        FSM.DW_LINE_Y_MAP[i] = math.floor(current_y + (entry.height / 2) + 0.5)
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
        
        local token_meta = entry.token_meta
        local entry_ass_vlines = {}
        for _, vl_indices in ipairs(entry.vlines) do
            local formatted_words = {}
            for _, j in ipairs(vl_indices) do
                local meta_item = token_meta[j]
                if meta_item.priority >= 1 or (meta_item.priority == 0 and meta_item.is_phrase) then
                    local final_bold = (meta_item.priority == 3) and Options.anki_highlight_bold or Options.dw_highlight_bold
                    local is_manual = (meta_item.priority == 1 or meta_item.priority == 2)
                    table.insert(formatted_words, format_highlighted_word({text = meta_item.text}, meta_item.color, color, meta_item.is_phrase, bold_state, true, final_bold, is_manual, Options.dw_bg_color, bg_alpha, Options.dw_border_size))
                else
                    table.insert(formatted_words, meta_item.text)
                end
            end
            
            local line_text = ""
            if Options.dw_original_spacing then
                line_text = table.concat(formatted_words, "")
            else
                line_text = compose_term_smart(formatted_words)
            end
            table.insert(entry_ass_vlines, line_text)
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
    local final_ass = ass .. string.format("{\\pos(960, 540)}{\\an5}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}{\\fs%d}%s%s", 
        Options.dw_border_size, Options.dw_shadow_offset, Options.dw_bg_color, Options.dw_bg_color, bg_alpha, bg_alpha, Options.dw_font_size, vsp_tag, block_text)
    
    -- Update Cache
    DW_DRAW_CACHE.view_center    = view_center
    DW_DRAW_CACHE.active_idx     = active_idx
    DW_DRAW_CACHE.subs_ptr       = subs
    DW_DRAW_CACHE.highlight_count = #FSM.ANKI_HIGHLIGHTS
    DW_DRAW_CACHE.layout_version  = FSM.LAYOUT_VERSION
    DW_DRAW_CACHE.cl             = FSM.DW_CURSOR_LINE
    DW_DRAW_CACHE.cw             = FSM.DW_CURSOR_WORD
    DW_DRAW_CACHE.al             = FSM.DW_ANCHOR_LINE
    DW_DRAW_CACHE.aw             = FSM.DW_ANCHOR_WORD
    DW_DRAW_CACHE.pending_version = (FSM.DW_CTRL_PENDING_VERSION or 0)
    DW_DRAW_CACHE.result          = final_ass
    
    return final_ass
end

local function draw_dw_tooltip(subs, target_line_idx, osd_y)
    local tooltip_sec_subs = (Tracks.sec.subs and #Tracks.sec.subs > 0) and Tracks.sec.subs or FSM.DW_TOOLTIP_SEC_SUBS
    if target_line_idx == -1 or not tooltip_sec_subs or #tooltip_sec_subs == 0 then return "" end
    
    -- Cache check (Task 1.3)
    if DW_TOOLTIP_DRAW_CACHE.target_idx == target_line_idx and 
       DW_TOOLTIP_DRAW_CACHE.osd_y == osd_y and 
       DW_TOOLTIP_DRAW_CACHE.version == FSM.LAYOUT_VERSION and
       DW_TOOLTIP_DRAW_CACHE.cl == FSM.DW_CURSOR_LINE and
       DW_TOOLTIP_DRAW_CACHE.cw == FSM.DW_CURSOR_WORD and
       DW_TOOLTIP_DRAW_CACHE.av == FSM.ANKI_VERSION then
        
        -- Restore hit zones from cache (Task 2.4)
        if DW_TOOLTIP_DRAW_CACHE.hit_zones then
            FSM.DW_TOOLTIP_HIT_ZONES = {}
            for k, v in ipairs(DW_TOOLTIP_DRAW_CACHE.hit_zones) do FSM.DW_TOOLTIP_HIT_ZONES[k] = v end
        end
        return DW_TOOLTIP_DRAW_CACHE.result
    end

    local primary_sub = subs[target_line_idx]
    if not primary_sub then return "" end
    
    local bg_alpha = calculate_ass_alpha(Options.tooltip_bg_opacity)
    local midpoint = (primary_sub.start_time + primary_sub.end_time) / 2
    local center_idx = get_center_index(tooltip_sec_subs, midpoint)
    if center_idx == -1 then return "" end
    
    local start_idx = math.max(1, center_idx - Options.tooltip_context_lines)
    local end_idx = math.min(#tooltip_sec_subs, center_idx + Options.tooltip_context_lines)
    
    local font_name = (Options.tooltip_font_name ~= "") and Options.tooltip_font_name or mp.get_property("sub-font", "Inter")
    local fs = Options.tooltip_font_size
    local line_height = fs * Options.tooltip_line_height_mul
    -- local bold = Options.tooltip_font_bold and "1" or "0" -- Moved per-line (Task 2.1)
    
    local max_text_w = 1400 -- Task 2.2 / Design Decision 3
    local lines_ass = {}
    local total_visual_lines = 0 -- Task 3.1
    local subtitle_metas = {} -- Storage for hit-zone calculation
    
    for i = start_idx, end_idx do
        local sub = tooltip_sec_subs[i]
        local tokens = get_sub_tokens(sub, true) -- Task 2.1
        
        -- Task 2.2 / 2.4: Wrap tokens
        local vline_indices = wrap_tokens(tokens, max_text_w, fs, font_name, true)
        
        -- Task 3.4: Preserve empty slots
        if #vline_indices == 0 then
            vline_indices = {{}} -- One empty visual line
        end
        
        local is_active = (i == center_idx)
        local base_color = is_active and Options.tooltip_active_color or Options.tooltip_context_color
        local opacity = is_active and Options.tooltip_active_opacity or Options.tooltip_context_opacity
        local bold_state = (is_active and Options.tooltip_active_bold or Options.tooltip_context_bold) and "1" or "0"
        local alpha_tag = string.format("{\\1a&H%s&}", calculate_ass_alpha(opacity))
        
        -- Inject highlights (respecting secondary track toggle)
        local force_plain = not Options.dw_sec_highlighting
        local token_meta = populate_token_meta(tooltip_sec_subs, i, tokens, base_color, sub.start_time, nil, force_plain, Options.tooltip_highlight_color, Options.tooltip_ctrl_select_color)
        
        local sub_visual_lines = {}
        local visual_lines_meta = {}
        for _, indices in ipairs(vline_indices) do
            local line_text = ""
            local line_w = 0
            local line_words = {}
            for _, idx in ipairs(indices) do
                local t = tokens[idx]
                local tm = token_meta[idx]
                local ww = dw_get_str_width(t.text, fs, font_name)
                
                if t.is_word and t.logical_idx then
                    table.insert(line_words, {
                        logical_idx = t.logical_idx,
                        x_offset = line_w,
                        width = ww
                    })
                end
                
                local final_bold = (tm.priority == 3) and Options.anki_highlight_bold or Options.tooltip_highlight_bold
                local is_man = (tm.priority == 1 or tm.priority == 2)
                line_text = line_text .. format_highlighted_word(t, tm.color, base_color, tm.is_phrase, bold_state, true, final_bold, is_man, Options.tooltip_bg_color, bg_alpha, Options.tooltip_border_size)
                line_w = line_w + ww
            end
            local line_prefix = string.format("{\\fn%s}{\\fs%d}{\\b%s}{\\1c&H%s&}", font_name, fs, bold_state, base_color)
            table.insert(sub_visual_lines, line_prefix .. alpha_tag .. line_text)
            table.insert(visual_lines_meta, {width = line_w, words = line_words})
            total_visual_lines = total_visual_lines + 1
        end
        
        table.insert(subtitle_metas, {sub_idx = i, visual_lines = visual_lines_meta})
        
        -- Task 2.3: Join visual lines within a subtitle with \N
        table.insert(lines_ass, table.concat(sub_visual_lines, "\\N"))
    end
    
    local d_gap = Options.tooltip_double_gap
    local vsp_base = Options.tooltip_vsp
    local b_gap_mul = Options.tooltip_block_gap_mul or 0
    local vsp_extra = d_gap and (fs * b_gap_mul / 2) or 0
    local separator = string.format("{\\vsp%g}%s{\\vsp%g}", vsp_base + vsp_extra, d_gap and "\\N\\N" or "\\N", vsp_base)

    local text_block = table.concat(lines_ass, separator)
    
    local bg_color = Options.tooltip_bg_color
    local bord = Options.tooltip_border_size
    local shad = Options.tooltip_shadow_offset
    
    -- Task 3.2: Refactor block_height calculation
    local layout_line_h = line_height + Options.tooltip_vsp
    local total_gap = calculate_sub_gap("tooltip", fs, Options.tooltip_line_height_mul, Options.tooltip_vsp)
    
    -- block_height = (total visual lines * height) + (logical gaps)
    local num_logical_blocks = end_idx - start_idx + 1
    local block_height = (total_visual_lines * layout_line_h)
    if num_logical_blocks > 1 then
        block_height = block_height + ((num_logical_blocks - 1) * total_gap)
    end
    
    local half_h = block_height / 2
    local margin = 20
    local screen_h = 1080
    
    -- Task 3.3: final_y positioning
    local logical_interval = layout_line_h + total_gap
    local final_y = osd_y + (Options.tooltip_y_offset_lines * logical_interval)
    
    if final_y - half_h < margin then
        final_y = margin + half_h
    elseif final_y + half_h > screen_h - margin then
        final_y = screen_h - margin - half_h
    end

    -- POPULATE HIT ZONES (Task 2.1 / 2.2 / 2.3)
    FSM.DW_TOOLTIP_HIT_ZONES = {}
    local cur_y = final_y - half_h
    for _, sm in ipairs(subtitle_metas) do
        for _, vl in ipairs(sm.visual_lines) do
            table.insert(FSM.DW_TOOLTIP_HIT_ZONES, {
                sub_idx = sm.sub_idx,
                y_top = cur_y,
                y_bottom = cur_y + layout_line_h,
                x_start = 1800 - vl.width, -- Right-aligned an6 logic
                total_width = vl.width,
                words = vl.words
            })
            cur_y = cur_y + layout_line_h
        end
        cur_y = cur_y + total_gap
    end

    local vsp_tag = Options.tooltip_vsp ~= 0 and string.format("{\\vsp%g}", Options.tooltip_vsp) or ""
    local base_bold = Options.tooltip_context_bold and "1" or "0"
    local ass = string.format("{\\fn%s}%s{\\pos(1800, %d)}{\\an6}{\\fs%d}{\\b%s}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}%s",
        font_name, vsp_tag, final_y, fs, base_bold, bord, shad, bg_color, bg_color, bg_alpha, bg_alpha, text_block)
        
    -- Update cache
    DW_TOOLTIP_DRAW_CACHE.target_idx = target_line_idx
    DW_TOOLTIP_DRAW_CACHE.osd_y = osd_y
    DW_TOOLTIP_DRAW_CACHE.version = FSM.LAYOUT_VERSION
    DW_TOOLTIP_DRAW_CACHE.cl = FSM.DW_CURSOR_LINE
    DW_TOOLTIP_DRAW_CACHE.cw = FSM.DW_CURSOR_WORD
    DW_TOOLTIP_DRAW_CACHE.av = FSM.ANKI_VERSION
    DW_TOOLTIP_DRAW_CACHE.result = ass
    
    -- Cache hit zones (Task 2.4)
    DW_TOOLTIP_DRAW_CACHE.hit_zones = {}
    for k, v in ipairs(FSM.DW_TOOLTIP_HIT_ZONES) do DW_TOOLTIP_DRAW_CACHE.hit_zones[k] = v end
        
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

local function dw_tooltip_hit_test(osd_x, osd_y)
    local tooltip_active = (FSM.DW_TOOLTIP_LINE ~= -1)
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not tooltip_active or not FSM.DW_TOOLTIP_HIT_ZONES then return nil, nil end
    if not dw_mode and not drum_mode then return nil, nil end
    if dw_mode and not Options.dw_sec_interactivity then return nil, nil end
    if not dw_mode and not Options.drum_sec_interactivity then return nil, nil end
    
    for _, line in ipairs(FSM.DW_TOOLTIP_HIT_ZONES) do
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

local function drum_osd_hit_test(osd_x, osd_y)
    if not FSM.DRUM_HIT_ZONES or not Options.osd_interactivity then return nil, nil, nil end
    
    local best_line = nil
    local min_y_dist = 60 -- Snapping threshold (pixels)
    
    for _, line in ipairs(FSM.DRUM_HIT_ZONES) do
        -- Horizontal alignment check (strict text bounds)
        local rel_x = osd_x - line.x_start
        if rel_x >= 0 and rel_x <= line.total_width then
            -- Vertical proximity check
            local dist_y = 0
            if osd_y < line.y_top then
                dist_y = line.y_top - osd_y
            elseif osd_y > line.y_bottom then
                dist_y = osd_y - line.y_bottom
            end
            
            -- Prioritize direct hits (dist_y == 0) or the closest line within threshold
            if dist_y < min_y_dist then
                min_y_dist = dist_y
                best_line = line
                if dist_y == 0 then break end -- Early exit on direct hit
            end
        end
    end

    if best_line then
        local line = best_line
        local rel_x = osd_x - line.x_start
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
        return line.sub_idx, best_logical_idx, line.is_pri
    end
    return nil, nil, nil
end

local function kardenwort_hit_test_all(osd_x, osd_y)
    if not Options.osd_interactivity then return nil, nil end
    
    if FSM.DRUM_WINDOW ~= "OFF" then
        if Options.dw_sec_interactivity then
            local l, w = dw_tooltip_hit_test(osd_x, osd_y)
            if l then return l, w end
        end
        if Options.dw_pri_interactivity then
            return dw_hit_test(osd_x, osd_y)
        end
        return nil, nil
    else
        local is_drum = (FSM.DRUM == "ON")
        local pri_enabled = is_drum and Options.drum_pri_interactivity or Options.srt_pri_interactivity
        local sec_enabled = is_drum and Options.drum_sec_interactivity or Options.srt_sec_interactivity
        
        if pri_enabled or sec_enabled then
            local line, word, hit_pri = drum_osd_hit_test(osd_x, osd_y)
            if not line then return nil, nil end
            
            -- Simple, flat filtering based on which screen was hit
            if hit_pri and not pri_enabled then return nil, nil end
            if not hit_pri and not sec_enabled then return nil, nil end
            
            return line, word
        end
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
        line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
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
    if not FSM.DW_MOUSE_DRAGGING or FSM.DRUM_WINDOW == "OFF" then return end
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
    Diagnostic.debug("TOOLTIP PIN: event=" .. tostring(tbl.event))
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then return end
    
    if tbl.event == "down" then
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_HOLDING = true
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end
        
        local osd_x, osd_y = dw_get_mouse_osd()
        local line_idx, _
        if dw_mode then
            line_idx, _ = dw_hit_test(osd_x, osd_y)
        else
            line_idx, _ = kardenwort_hit_test_all(osd_x, osd_y)
        end
        
        if line_idx then
            FSM.DW_TOOLTIP_LOCKED_LINE = -1
            FSM.DW_TOOLTIP_LINE = line_idx
            local y = get_tooltip_line_y(line_idx, osd_y)
            if y then y = math.floor(y + 0.5) end
            local ass = draw_dw_tooltip(subs, line_idx, y)
            if ass ~= dw_tooltip_osd.data then
                dw_tooltip_osd.data = ass
                dw_tooltip_osd:update()
            end
            Diagnostic.debug("TOOLTIP ROUTE: PIN->" .. (dw_mode and "DW" or "DRUM") .. " line=" .. tostring(line_idx))
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
        clear_tooltip_overlay("hover-mode-click")
    end
end

local function cmd_dw_tooltip_toggle()
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then return end
    
    -- If already forced ON, always toggle OFF regardless of current target match
    if FSM.DW_TOOLTIP_FORCE then
        Diagnostic.info("TOOLTIP TOGGLE: OFF (" .. (dw_mode and "DW" or "DRUM") .. ")")
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("toggle-off")
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
        Diagnostic.info("TOOLTIP TOGGLE: ON (" .. (dw_mode and "DW" or "DRUM") .. ")")
        FSM.DW_TOOLTIP_FORCE = true
        FSM.DW_TOOLTIP_LINE = line_idx
        local y = get_tooltip_line_y(line_idx, nil)
        if not y then
            y = 540 -- center of 1080p OSD
        else
            y = math.floor(y + 0.5)
        end
        local ass = draw_dw_tooltip(subs, line_idx, y)
        if ass ~= dw_tooltip_osd.data then
            dw_tooltip_osd.data = ass
            dw_tooltip_osd:update()
        end
    end
end

local function dw_tooltip_mouse_update()
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then
        clear_tooltip_overlay("mode-ineligible")
        FSM.DW_TOOLTIP_FORCE = false
        return
    end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, _
    if dw_mode then
        -- In DW, always target via primary DW hit-test for tooltip routing.
        -- This avoids hover flicker on borders caused by mixed tooltip-vs-primary hit-zones.
        line_idx, _ = dw_hit_test(osd_x, osd_y)
    elseif FSM.DW_TOOLTIP_HOLDING then
        -- During RMB hold in non-DW modes, keep stable routing through shared hit-test.
        line_idx, _ = kardenwort_hit_test_all(osd_x, osd_y)
    else
        line_idx, _ = kardenwort_hit_test_all(osd_x, osd_y)
    end
    
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
            local y = get_tooltip_line_y(target_l, nil)
            if y then
                y = math.floor(y + 0.5)
                local new_ass = draw_dw_tooltip(subs, target_l, y)
                if new_ass ~= dw_tooltip_osd.data then
                    dw_tooltip_osd.data = new_ass
                    dw_tooltip_osd:update()
                end
            else
                clear_tooltip_overlay("forced-target-missing")
            end
        end
        return
    end
    
    -- Selection-Aware Suppression: Hide tooltip during dragging or if currently locked to this line
    if FSM.DW_MOUSE_DRAGGING or (line_idx and line_idx == FSM.DW_TOOLTIP_LOCKED_LINE) then
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            clear_tooltip_overlay("drag-or-locked")
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
            local target_y = get_tooltip_line_y(target_l, nil)
            if target_y then
                target_y = math.floor(target_y + 0.5)
                -- Update OSD data on every tick when line is visible to ensure smooth following during scroll
                local new_ass = draw_dw_tooltip(subs, target_l, target_y)
                FSM.DW_TOOLTIP_LINE = target_l
                if new_ass ~= dw_tooltip_osd.data then
                    dw_tooltip_osd.data = new_ass
                    dw_tooltip_osd:update()
                end
            else
                -- Only dismiss if we are NOT holding RMB (prevents jitter in gaps)
                if not FSM.DW_TOOLTIP_HOLDING and FSM.DW_TOOLTIP_LINE ~= -1 then
                    clear_tooltip_overlay("target-y-missing")
                end
            end
        elseif not FSM.DW_TOOLTIP_HOLDING then
            -- Sticky Hover: Only dismiss on gaps if we are NOT holding RMB
            if FSM.DW_TOOLTIP_LINE ~= -1 then
                clear_tooltip_overlay("hover-gap")
            end
        end
    else
        -- CLICK mode or Selection Protected: check if we left the pinned line focus
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            if line_idx ~= FSM.DW_TOOLTIP_LINE then
                clear_tooltip_overlay("click-focus-left")
            end
        end
    end
end



local function dw_anki_export_selection()
    local ok, err = pcall(function()
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end
        
        local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
        local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
        local params = {}
        local term = ""
        local context_line = ""
        local time_pos = 0
        local is_sentence_boundary = false
        local pivot_pos = 0
        local advanced_index = nil

        if al ~= -1 and aw ~= -1 and cl ~= -1 and cw ~= -1 then
            local p1_l, p1_w, p2_l, p2_w
            if al < cl or (al == cl and aw <= cw) then
                p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
            else
                p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
            end
            
            params = { type = "RANGE", p1_l = p1_l, p1_w = p1_w, p2_l = p2_l, p2_w = p2_w }
            term = prepare_export_text(params, { clean = true, restore_sentence = true })
            
            -- Requirement: Reconstruct advanced_index (word-based only)
            local indices = {}
            local pivot_idx = 1
            for i = p1_l, p2_l do
                local sub = subs[i]
                if sub then
                    local raw_text = sub.text:gsub("\n", " ")
                    local tokens = build_word_list_internal(raw_text, true)
                    for _, t in ipairs(tokens) do
                        if t.is_word then
                            local in_range = true
                            if i == p1_l and t.logical_idx < p1_w - L_EPSILON then in_range = false end
                            if i == p2_l and t.logical_idx > p2_w + L_EPSILON then in_range = false end
                            if in_range then
                                table.insert(indices, string.format("%d:%g:%d", i - p1_l, t.logical_idx, pivot_idx))
                                pivot_idx = pivot_idx + 1
                            end
                        end
                    end
                end
            end
            advanced_index = table.concat(indices, ",")
            
            -- Context Extraction Logic
            local ctx_parts = {}
            local char_offset = 0
            pivot_pos = -1
            local start_k = math.max(1, p1_l - Options.anki_context_lines)
            for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines) do
                if subs[k] then 
                    local text = subs[k].text:gsub("{[^}]+}", "")
                    
                    if k == p1_l then
                        -- Precision Anchor
                        local first_word = term:match("%S+") or ""
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
            time_pos = subs[p1_l].start_time + 0.001
        elseif cl ~= -1 and subs[cl] then
            params = { type = "POINT", line = cl, word = cw }
            term = prepare_export_text(params, { clean = true, restore_sentence = true })
            
            if cw ~= -1 then
                advanced_index = string.format("0:%g:1", cw)
            end

            -- Context Extraction
            local ctx_parts = {}
            local char_offset = 0
            pivot_pos = -1
            local start_k = math.max(1, cl - Options.anki_context_lines)
            for k = start_k, math.min(#subs, cl + Options.anki_context_lines) do
                if subs[k] then 
                    local text = subs[k].text:gsub("{[^}]+}", "")
                    
                    if k == cl then
                        local s = text:find(term, 1, true)
                        if s then
                            pivot_pos = char_offset + s + (#term / 2)
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
            time_pos = subs[cl].start_time + 0.001
        end


        if term and term ~= "" then
            -- Clean context: remove ASS tags
            context_line = context_line:gsub("{[^}]+}", "")
            local term_words = build_word_list(term)
            local effective_limit = math.max(Options.anki_context_max_words, #term_words + 20)
            local extracted_context = extract_anki_context(context_line, term, effective_limit, pivot_pos, advanced_index)
            -- Use the multi-index generated above
            save_anki_tsv_row(term, extracted_context, time_pos, advanced_index)
            show_osd("Anki Highlight Saved: " .. term)

            -- In-memory update was already performed by save_anki_tsv_row.
            -- Removing redundant full-file reload to prevent UI stuttering.
            dw_reset_selection()
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
    FSM.DW_CTRL_PENDING_LIST = {}
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    if FSM.DRUM_WINDOW ~= "OFF" then 
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        dw_osd:update() 
    end
end

local function get_dw_selection_bounds()
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    
    if al == -1 or aw == -1 or cl == -1 or cw == -1 then return nil end
    if al == cl and logical_cmp(aw, cw) then return nil end -- Single word is not a "range selection" in this context
    
    if al < cl or (al == cl and aw < cw + L_EPSILON) then
        return al, aw, cl, cw
    else
        return cl, cw, al, aw
    end
end

-- Context-Aware Escape: Deterministic staged selection peel-back.
-- Stage 1: Clear Pink Set (ctrl pending set)
-- Stage 2: Clear Yellow Range (if anchor exists and is different from cursor)
-- Stage 3: Clear Yellow Pointer (hides the highlight) and syncs cursor to active line
-- No implicit window close occurs in cmd_dw_esc itself.

local function cmd_dw_esc()
    -- Stage 1: Clear Pink Set (Purple highlights)
    if next(FSM.DW_CTRL_PENDING_SET) then
        FSM.DW_CTRL_PENDING_SET = {}
        FSM.DW_CTRL_PENDING_LIST = {}
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() 
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end

    -- Stage 2: Clear Yellow Range (multi-word selection)
    -- get_dw_selection_bounds returns nil if it's a single-word pointer
    if get_dw_selection_bounds() then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() 
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end

    -- Stage 3: Clear Yellow Pointer & Full Reset
    if FSM.DW_CURSOR_WORD ~= -1 then
        -- Re-anchor from live playback time to avoid latching a stale pre-boundary line
        -- when Esc lands between render ticks.
        local time_pos = mp.get_property_number("time-pos") or 0
        local live_active_idx = get_center_index(Tracks.pri.subs, time_pos)
        if live_active_idx and live_active_idx ~= -1 then
            FSM.DW_ACTIVE_LINE = live_active_idx
        end
        dw_reset_selection()
        -- After full selection clear via Esc, return to normal auto-follow behavior.
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_SEEKING_MANUALLY = false
        FSM.DW_SEEK_TARGET = -1
        return
    end
end


local function ctrl_toggle_word(line_idx, word_idx, no_sync)
    if line_idx < 1 or word_idx < 0 then return end
    
    if not FSM.DW_CTRL_PENDING_SET[line_idx] then
        FSM.DW_CTRL_PENDING_SET[line_idx] = {}
    end
    
    local line_set = FSM.DW_CTRL_PENDING_SET[line_idx]
    if line_set[word_idx] then
        line_set[word_idx] = nil
        -- Clean up empty line tables to keep iteration fast
        local has_any = false
        for _ in pairs(line_set) do has_any = true break end
        if not has_any then FSM.DW_CTRL_PENDING_SET[line_idx] = nil end
    else
        line_set[word_idx] = {line = line_idx, word = word_idx}
    end
    if not no_sync then
        sync_ctrl_pending_list()
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then 
            dw_osd:update() 
        end
    end
end

local function ctrl_commit_set(line_idx, word_idx)
    Diagnostic.info(string.format("ctrl_commit_set(line=%s, word=%s)", tostring(line_idx), tostring(word_idx)))
    -- Check if cursor word is in set
    local line_set = FSM.DW_CTRL_PENDING_SET[line_idx]
    if not line_set or not line_set[word_idx] then
        Diagnostic.info("ctrl_commit_set: word NOT in set, falling back")
        -- Fallback to plain MMB single-click export
        dw_anki_export_selection()
        return
    end
    
    -- Use pre-sorted list from FSM
    local members = FSM.DW_CTRL_PENDING_LIST
    if #members == 0 then return end

    
    -- Requirement: Unified Paired Export
    local term = prepare_export_text({ type = "SET", members = members }, { clean = true, restore_sentence = true })
    
    local subs = Tracks.pri.subs
    local p1_l = members[1].line
    local p2_l = members[#members].line
    local time_pos = subs[p1_l].start_time + 0.001

    -- Context Extraction
    local ctx_parts = {}
    local char_offset = 0
    local pivot_pos = -1
    local start_k = math.max(1, p1_l - Options.anki_context_lines)
    for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines) do
        if subs[k] then 
            local text = subs[k].text:gsub("{[^}]+}", "")
            
            if k == p1_l then
                local first_word = term:match("%S+") or ""
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
    local context_line = table.concat(ctx_parts, "\0")
    
    -- Build advanced index string
    local indices = {}
    for i, m in ipairs(members) do
        table.insert(indices, string.format("%d:%g:%d", m.line - p1_l, m.word, i))
    end
    local advanced_index = table.concat(indices, ",")
    
    save_anki_tsv_row(term, extract_anki_context(context_line, term, Options.anki_context_max_words, pivot_pos, advanced_index), subs[p1_l].start_time + 0.001, advanced_index)
    show_osd("Anki Paired Saved: " .. term)

    
    dw_reset_selection()
    
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
            local is_tooltip_hit = dw_tooltip_hit_test(osd_x, osd_y)
            local line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
            
            if line_idx then
                FSM.DW_TOOLTIP_LOCKED_LINE = line_idx

                if FSM.DW_TOOLTIP_LINE ~= -1 and not is_tooltip_hit then
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
                        FSM.DW_CURSOR_X = nil
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    elseif is_shift then
                        if FSM.DW_ANCHOR_LINE == -1 then
                            FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
                            FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
                        end
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_CURSOR_X = nil
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
                local line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
                
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
        local line_set = FSM.DW_CTRL_PENDING_SET[FSM.DW_ANCHOR_LINE]
        if line_set and line_set[FSM.DW_ANCHOR_WORD] then starts_pink = true end
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
                                ctrl_toggle_word(i, t.logical_idx, true)
                            end
                        end
                        if logical_cmp(t.logical_idx, e_w) then in_range = false break end
                    end
                end
            end
        end
        sync_ctrl_pending_list()
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then 
            dw_osd:update() 
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
            line, word = kardenwort_hit_test_all(osd_x, osd_y)
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
    local line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
    if not line_idx then return end

    local sub = subs[line_idx]
    if sub and sub.start_time then
        -- [v1.58.51] Intentional Focus Handover
        FSM.IGNORE_NEXT_JUMP = true
        FSM.ACTIVE_IDX = line_idx
        if #Tracks.sec.subs > 0 then FSM.SEC_ACTIVE_IDX = math.min(line_idx, #Tracks.sec.subs) end
        FSM.JUST_JERKED_TO = -1
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown

        local s, _ = get_effective_boundaries(subs, sub, line_idx)
        mp.commandv("seek", s, "absolute+exact")
        FSM.last_paused_sub_end = nil
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
        if FSM.BOOK_MODE and not FSM.DW_SEEKING_MANUALLY then
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

    -- Book Mode parity for DM mini (DRUM=ON, DW_WINDOW=OFF):
    -- keep follow enabled but page the viewport with dw_ensure_visible,
    -- matching the DW Book Mode behavior.
    if is_drum and FSM.DW_FOLLOW_PLAYER and FSM.BOOK_MODE and not FSM.DW_SEEKING_MANUALLY and #Tracks.pri.subs > 0 then
        local pri_active_idx = get_center_index(Tracks.pri.subs, time_pos)
        if pri_active_idx and pri_active_idx ~= -1 then
            if FSM.DW_VIEW_CENTER == -1 then
                FSM.DW_VIEW_CENTER = pri_active_idx
            end
            dw_ensure_visible(pri_active_idx, true)
        end
    end

    local pri_active_idx = (#Tracks.pri.subs > 0) and get_center_index(Tracks.pri.subs, time_pos) or -1
    local pri_view_center = FSM.DW_VIEW_CENTER
    if FSM.DW_FOLLOW_PLAYER then
        pri_view_center = (is_drum and FSM.BOOK_MODE) and FSM.DW_VIEW_CENTER or pri_active_idx
    end
    if pri_view_center == -1 then pri_view_center = pri_active_idx end

    -- Draw Primary FIRST, Secondary SECOND (so Secondary is on top in Z-order)
    if pri_use_osd and #Tracks.pri.subs > 0 then
        local active_idx = pri_active_idx
        local view_center = pri_view_center
        
        local pri_plain = is_drum and (not Options.drum_pri_highlighting) or (not Options.srt_pri_highlighting)
        ass_text = ass_text .. draw_drum(Tracks.pri.subs, view_center, active_idx, pri_pos, time_pos, font_size, FSM.DRUM_HIT_ZONES, pri_plain, true)
    end

    if sec_use_osd and #Tracks.sec.subs > 0 then
        local active_idx = get_center_index(Tracks.sec.subs, time_pos)
        -- [v1.58.52] Secondary track mirrors primary viewport offset in all follow modes.
        local view_center = active_idx
        if pri_active_idx ~= -1 and pri_view_center ~= -1 then
            local offset = pri_view_center - pri_active_idx
            view_center = math.max(1, math.min(#Tracks.sec.subs, active_idx + offset))
        end
        
        local sec_plain = is_drum and (not Options.drum_sec_highlighting) or (not Options.srt_sec_highlighting)
        ass_text = ass_text .. draw_drum(Tracks.sec.subs, view_center, active_idx, sec_pos, time_pos, font_size, FSM.DRUM_HIT_ZONES, sec_plain, false)
    end
    
    drum_osd.data = ass_text
    drum_osd:update()
end

-- =========================================================================
-- AUTOPAUSE CONTROLLER
-- =========================================================================

local function tick_autopause(time_pos)
    if FSM.AUTOPAUSE ~= "ON" or FSM.SPACEBAR ~= "IDLE" then return end
    if FSM.SCHEDULED_REPLAY_START or FSM.LOOP_MODE == "ON" then return end
    if FSM.MEDIA_STATE == "NO_SUBS" then return end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    -- [v1.58.51] Hardened Autopause via Sticky Focus
    -- Use the Sentinel (ACTIVE_IDX) to determine exactly when the audible tail ends.
    local active_idx = FSM.ACTIVE_IDX
    if active_idx == -1 or not subs[active_idx] then
        -- Fallback if sentinel is lost
        active_idx = get_center_index(subs, time_pos)
    end
    if active_idx == -1 then return end

    -- [v1.58.54] Skip autopause while transiting through the rewind zone after Shift+A/D.
    -- Uses <= so the exact boundary tick is still suppressed; the inhibit is cleared
    -- only after jerk-back has also been evaluated (see end of main tick function).
    -- [20260510193230] Special case: within-subtitle rewind should still allow autopause at end.
    local in_rewind_transit = FSM.TIMESEEK_INHIBIT_UNTIL and time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL
    local within_subtitle_rewind = in_rewind_transit and FSM.REWIND_START_IDX and active_idx == FSM.REWIND_START_IDX

    -- Suppress autopause only during cross-subtitle rewind transit
    if in_rewind_transit and FSM.REWIND_TRANSIT_CROSS_CARD and not within_subtitle_rewind then return end

    local _, sub_end = get_effective_boundaries(subs, subs[active_idx], active_idx)
    if not sub_end then return end

    -- Check if we've reached the end of the padded window
    -- Use an inclusive check to ensure we don't skip the pause frame.
    local diff = sub_end - time_pos
    if diff > Options.pause_padding or diff < -Options.autopause_overshoot then
        return
    end

    -- Prevent re-triggering for the same subtitle segment
    if FSM.last_paused_sub_end == sub_end then return end

    -- Ensure we are actually on a subtitle (using internal state rather than transient mpv visibility)
    -- This fixes the "Stops stopping" bug when text clears before the audio tail finishes.
    local raw_text_primary = subs[active_idx].text or ""
    local raw_text_secondary = (Tracks.sec.subs[active_idx] and Tracks.sec.subs[active_idx].text) or ""
    
    if raw_text_primary == "" and raw_text_secondary == "" then return end

    -- Karaoke Mode: Don't pause if we are in the middle of a phrase with highlights
    if FSM.KARAOKE == "PHRASE" then
        local has_karaoke = string.find(raw_text_primary, Options.karaoke_token, 1, true)
        if not has_karaoke then has_karaoke = string.find(raw_text_secondary, Options.karaoke_token, 1, true) end
        if has_karaoke then return end
    end

    mp.set_property_bool("pause", true)
    FSM.last_paused_sub_end = sub_end

end

local function tick_loop(time_pos)
    if FSM.LOOP_MODE ~= "ON" then return end
    if not FSM.LOOP_START or not FSM.LOOP_END then return end

    if time_pos >= FSM.LOOP_END - Options.pause_padding then
        if FSM.LOOP_ARMED then
            FSM.LOOP_ARMED = false
            FSM.IGNORE_NEXT_JUMP = true
            
            if FSM.REPLAY_REMAINING > 1 then
                FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
                local pri_subs = Tracks.pri.subs
                if pri_subs and #pri_subs > 0 then
                    local idx = get_center_index(pri_subs, FSM.LOOP_START)
                    if idx ~= -1 then FSM.ACTIVE_IDX = idx end
                end
                local sec_subs = Tracks.sec.subs
                if sec_subs and #sec_subs > 0 then
                    local idx = get_center_index(sec_subs, FSM.LOOP_START)
                    if idx ~= -1 then FSM.SEC_ACTIVE_IDX = idx end
                end
                mp.commandv("seek", FSM.LOOP_START, "absolute+exact")
            else
                FSM.REPLAY_REMAINING = 0
                FSM.LOOP_MODE = "OFF"
            end
            
            -- [v1.58.48] Spacebar Override: If holding Space, break the loop
            -- so it repeats once and then continues over the subtitle border.
            if FSM.SPACEBAR == "HOLDING" then
                FSM.LOOP_MODE = "OFF"
                FSM.REPLAY_REMAINING = 0
            end
        end
    else
        FSM.LOOP_ARMED = true
    end
end

local function tick_scheduled_replay(time_pos)
    if not FSM.SCHEDULED_REPLAY_START or not FSM.SCHEDULED_REPLAY_END then return false end
    
    if time_pos >= FSM.SCHEDULED_REPLAY_END - Options.pause_padding then
        if FSM.REPLAY_REMAINING > 1 then
            FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
            FSM.IGNORE_NEXT_JUMP = true
            FSM.last_paused_sub_end = nil
            local pri_subs = Tracks.pri.subs
            if pri_subs and #pri_subs > 0 then
                local idx = get_center_index(pri_subs, FSM.SCHEDULED_REPLAY_START)
                if idx ~= -1 then FSM.ACTIVE_IDX = idx end
            end
            local sec_subs = Tracks.sec.subs
            if sec_subs and #sec_subs > 0 then
                local idx = get_center_index(sec_subs, FSM.SCHEDULED_REPLAY_START)
                if idx ~= -1 then FSM.SEC_ACTIVE_IDX = idx end
            end
            mp.commandv("seek", FSM.SCHEDULED_REPLAY_START, "absolute+exact")
            return true
        else
            FSM.REPLAY_REMAINING = 0
            FSM.SCHEDULED_REPLAY_START = nil
            FSM.SCHEDULED_REPLAY_END = nil
            if FSM.SPACEBAR == "IDLE" and Options.replay_autostop then
                mp.set_property_bool("pause", true)
            end
            return true
        end
    end
    return false
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

    -- [v1.58.48] Ghost Hold Recovery
    -- If Space is 'HOLDING' due to a suspected ghost event at 's' press,
    -- but no physical 'DOWN' event has refreshed it within 2 seconds, revert to IDLE.
    if FSM.SPACEBAR == "HOLDING" and FSM.GHOST_HOLD_EXPIRY and mp.get_time() > FSM.GHOST_HOLD_EXPIRY then
        FSM.SPACEBAR = "IDLE"
        FSM.GHOST_HOLD_EXPIRY = nil
        FSM.PHYSICAL_SPACE_HOLD = false

    end

    -- [v1.58.48] Universal Manual Seek Detection
    -- Detects any significant jump (native keys, script keys, or mouse)
    if FSM.last_time_pos and math.abs(time_pos - FSM.last_time_pos) > 0.3 then
        if not FSM.IGNORE_NEXT_JUMP then
            -- Any manual navigation resets Autopause state so it fires again at the new location.
            FSM.last_paused_sub_end = nil
            FSM.SCHEDULED_REPLAY_START = nil
            FSM.SCHEDULED_REPLAY_END = nil
            -- TIMESEEK_INHIBIT_UNTIL is NOT cleared here — it is cleared only by
            -- the explicit inhibit gate (time_pos > TIMESEEK_INHIBIT_UNTIL) below.
            -- Clearing it in generic jump detection would allow autopause to fire at
            -- intermediate sub boundaries during rewind transit (ZID 20260509233440).
            FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
            if FSM.LOOP_MODE == "ON" then
                -- Persistent Loop (Autopause OFF only): Re-anchor loop to the new subtitle.
                local subs = Tracks.pri.subs
                if subs and #subs > 0 then
                    local idx = get_center_index(subs, time_pos)
                    if idx ~= -1 then
                        FSM.LOOP_START = subs[idx].start_time
                        FSM.LOOP_END = subs[idx].end_time
                        FSM.LOOP_ARMED = true
                        show_osd("Loop: Line " .. idx)
                    end
                end
            end
        end
    end
    FSM.IGNORE_NEXT_JUMP = false
    FSM.last_time_pos = time_pos

    local did_scheduled_replay = tick_scheduled_replay(time_pos)

    -- Execute Autopause and Loop
    -- IMPORTANT: Loop Mode is only valid when Autopause is OFF.
    if FSM.AUTOPAUSE == "ON" and FSM.SPACEBAR == "IDLE" and not did_scheduled_replay then
        tick_autopause(time_pos)
    elseif FSM.AUTOPAUSE == "OFF" and FSM.LOOP_MODE == "ON" then
        tick_loop(time_pos)
    end

    -- Sync active line for Drum/DW logic
    local active_idx = -1
    if #Tracks.pri.subs > 0 then
        active_idx = get_center_index(Tracks.pri.subs, time_pos)
        if active_idx ~= -1 then
            -- [v1.58.51] Phrases Mode "Jerk Back" Logic
            -- Only trigger for NATURAL transitions. Skip during manual seek cooldown and during
            -- time-based rewind transit (TIMESEEK_INHIBIT_UNTIL), where MOVIE-like seamless flow
            -- is expected: no jerking, no overlap-driven snaps.
            local hold_elapsed = mp.get_time() - (FSM.space_down_time or 0)
            local phrase_space_movie_override = FSM.AUTOPAUSE == "ON"
                and FSM.IMMERSION_MODE == "PHRASE"
                and FSM.PHYSICAL_SPACE_HOLD
                and hold_elapsed > Options.space_tap_delay

            if FSM.IMMERSION_MODE == "PHRASE" and not phrase_space_movie_override and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN
               and (not FSM.TIMESEEK_INHIBIT_UNTIL or not FSM.REWIND_TRANSIT_CROSS_CARD) then
                if FSM.ACTIVE_IDX ~= -1 and active_idx > FSM.ACTIVE_IDX and active_idx <= FSM.ACTIVE_IDX + 5 then
                    local s_next, _ = get_effective_boundaries(Tracks.pri.subs, Tracks.pri.subs[active_idx], active_idx)
                    if s_next and (time_pos - s_next) > Options.nav_tolerance then
                        mp.commandv("seek", s_next, "absolute+exact")
                        FSM.IGNORE_NEXT_JUMP = true
                        FSM.JUST_JERKED_TO = active_idx
                    end
                end
            end

            -- [v1.58.54] Clear rewind-transit inhibit AFTER jerk-back has been evaluated,
            -- using strict > so both autopause and jerk-back are suppressed on the boundary tick.
            -- [20260510193230] Also clear rewind start index when transit ends.
            if FSM.TIMESEEK_INHIBIT_UNTIL and time_pos > FSM.TIMESEEK_INHIBIT_UNTIL then
                FSM.TIMESEEK_INHIBIT_UNTIL = nil
                FSM.REWIND_START_IDX = nil
                FSM.REWIND_TRANSIT_CROSS_CARD = false
            end

            -- Clear jerk flag once we've moved past the previous sub's technical end
            if FSM.JUST_JERKED_TO ~= -1 and FSM.JUST_JERKED_TO == active_idx then
                local prev_idx = active_idx - 1
                if prev_idx >= 1 and Tracks.pri.subs[prev_idx] then
                    if time_pos > Tracks.pri.subs[prev_idx].end_time then
                        FSM.JUST_JERKED_TO = -1
                    end
                else
                    FSM.JUST_JERKED_TO = -1
                end
            end

            FSM.ACTIVE_IDX = active_idx
            FSM.DW_ACTIVE_LINE = active_idx
            
            -- [v1.58.49] Universal Cursor Synchronization
            -- Ensures that the "copy focus" always tracks playback when in follow mode,
            -- even if the Drum Window is closed (e.g., purely in Drum Mode on-screen).
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
                end
            end
        end
    end

    -- [20260507154518] Maintain secondary Sticky Sentinel (mirrors primary ACTIVE_IDX pattern).
    -- [20260509233440] Gate with MANUAL_NAV_COOLDOWN so that cmd_dw_seek_delta's explicit
    -- SEC_ACTIVE_IDX assignment is not immediately overwritten by the natural sentinel scan.
    -- During the cooldown window, the secondary sentinel preserves the seek target.
    if #Tracks.sec.subs > 0 and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN then
        local sec_idx = get_center_index(Tracks.sec.subs, time_pos)
        if sec_idx ~= -1 then
            FSM.SEC_ACTIVE_IDX = sec_idx
        end
    end

    -- Manage native subtitle suppression
    -- We hide native subs if OSD rendering is active OR Drum Window is open.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local dw_active = (FSM.DRUM_WINDOW ~= "OFF")
    
    -- Independent OSD render decisions:
    -- 1. Always use OSD if Drum Mode is ON.
    -- 2. Use OSD for SRT if custom fonts are configured.
    -- 3. [20260501163905] Force OSD if a highlight (Yellow Pointer or Pink Set) exists on the active line.
    -- 4. NEVER use OSD for ASS in Regular mode (to preserve styling/layout).
    local has_ptr = (FSM.DW_CURSOR_WORD ~= -1 and active_idx == FSM.DW_CURSOR_LINE)
    local has_pink = (next(FSM.DW_CTRL_PENDING_SET) ~= nil)
    local pri_use_osd = FSM.native_sub_vis and ((FSM.DRUM == "ON") or (not Tracks.pri.is_ass and (use_osd_for_srt or has_ptr or has_pink)))
    local sec_use_osd = FSM.native_sec_sub_vis and ((FSM.DRUM == "ON") or (not Tracks.sec.is_ass and (use_osd_for_srt or has_ptr or has_pink)))

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
        Diagnostic.error("master_tick crash: " .. tostring(err))
    end
end
mp.add_periodic_timer(Options.tick_rate, master_tick)

-- =========================================================================
-- ACTION BINDINGS
-- =========================================================================

local function cmd_toggle_autopause()
    FSM.AUTOPAUSE = (FSM.AUTOPAUSE == "ON") and "OFF" or "ON"
    if FSM.AUTOPAUSE == "ON" then
        FSM.LOOP_MODE = "OFF"
    else
        FSM.SCHEDULED_REPLAY_START = nil
        FSM.SCHEDULED_REPLAY_END = nil
    end
    show_osd("Autopause: " .. FSM.AUTOPAUSE)
end

local function cmd_toggle_karaoke()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.MEDIA_STATE:match("ASS") then
        show_osd("X")
        return
    end
    FSM.KARAOKE = (FSM.KARAOKE == "WORD") and "PHRASE" or "WORD"
    if FSM.KARAOKE == "WORD" then
        show_osd("Pause Mode: EVERY WORD", Options.osd_duration + 0.5)
    else
        show_osd("Pause Mode: END OF PHRASE")
    end
end

local function cmd_smart_space(table)
    if table.event == "down" then
        FSM.GHOST_HOLD_EXPIRY = nil -- User is physically holding, clear ghost timer
        FSM.PHYSICAL_SPACE_HOLD = true
        if FSM.SPACEBAR == "IDLE" then
            FSM.SPACEBAR = "HOLDING"
            FSM.space_down_time = mp.get_time()
            FSM.initial_pause_state = mp.get_property_bool("pause", true)
            if FSM.initial_pause_state then mp.set_property_bool("pause", false) end
        end
    elseif table.event == "up" then
        FSM.SPACEBAR = "IDLE"
        FSM.PHYSICAL_SPACE_HOLD = false
        FSM.space_up_time = mp.get_time()
        if (mp.get_time() - FSM.space_down_time) <= Options.space_tap_delay then
            mp.set_property_bool("pause", not FSM.initial_pause_state)
        end
    end
end

local function cmd_toggle_anki_global()
    Options.anki_global_highlight = not Options.anki_global_highlight
    show_osd("Anki Global Highlight: " .. (Options.anki_global_highlight and "ON" or "OFF"))
    flush_rendering_caches()
    drum_osd:update()
    if dw_osd then dw_osd:update() end
end

local function cmd_toggle_drum()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
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
        clear_tooltip_overlay("drum-on-transition")
        -- We no longer update FSM.native_sub_vis here because it's managed by cmd_toggle_sub_vis
        -- and would be overwritten by our own suppression logic.
        
        -- Boot subs for drum memory
        if Tracks.pri.path then Tracks.pri.subs = load_sub(Tracks.pri.path, false) end
        if Tracks.sec.path then Tracks.sec.subs = load_sub(Tracks.sec.path, false) end

        show_osd("Drum Mode: ON")
    else
        FSM.DRUM = "OFF"
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("drum-off-transition")
        show_osd("Drum Mode: OFF")
    end
    update_interactive_bindings()
    flush_rendering_caches()
    -- master_tick handles the sub-visibility property suppression
    drum_osd.data = ""
    drum_osd:update()
end


local function cmd_dw_scroll(dir)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    -- [v1.58.52] Bootstrap: If the viewport hasn't been explicitly set yet,
    -- anchor it to the current active index before applying the scroll delta.
    if FSM.DW_VIEW_CENTER == -1 then
        local time_pos = mp.get_property_number("time-pos") or 0
        FSM.DW_VIEW_CENTER = get_center_index(subs, time_pos)
        if FSM.DW_VIEW_CENTER == -1 then FSM.DW_VIEW_CENTER = 1 end
    end
    FSM.DW_FOLLOW_PLAYER = false
    FSM.DW_VIEW_CENTER = math.max(1, math.min(#subs, FSM.DW_VIEW_CENTER + dir))
    -- Keep null-pointer source in sync with manual viewport scroll to avoid stale entry line
    -- on the next UP/DOWN/LEFT/RIGHT activation after Esc.
    if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_CURSOR_LINE = FSM.DW_VIEW_CENTER
    end
    dw_sync_cursor_to_mouse()
end

local function cmd_dw_wheel_scroll(dir)
    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, _ = kardenwort_hit_test_all(osd_x, osd_y)
    
    -- In Drum Window (DOCKED), ALWAYS scroll.
    -- In Drum Mode (OSD), also ALWAYS scroll to match DW field behavior
    -- (not only when hovering exact subtitle hit-zones).
    if FSM.DRUM_WINDOW ~= "OFF" or FSM.DRUM == "ON" or line_idx then
        cmd_dw_scroll(dir)
    end
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
    local tokens = get_sub_tokens(sub)
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
            if logical_cmp(visual_to_logical[wi], FSM.DW_CURSOR_WORD) then
                return vl_left + pos + ww / 2
            end
            pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
        end
    end
    return nil
end

local function ensure_sub_layout(sub)
    if not sub then return nil end
    if sub.layout_cache and sub.layout_cache.version == FSM.LAYOUT_VERSION then
        return sub.layout_cache.entry
    end

    local tokens = get_sub_tokens(sub)
    if #tokens == 0 then tokens = {{text=""}} end
    local font_size = Options.dw_font_size
    local font_name = Options.dw_font_name
    local max_w = 1860
    local space_w = dw_get_str_width(" ", font_size, font_name)

    local logical_to_visual = {}
    for j, t in ipairs(tokens) do
        if t.logical_idx then logical_to_visual[t.logical_idx] = j end
    end

    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    for j, w in ipairs(tokens) do
        local ww = dw_get_str_width(w, font_size, font_name)
        local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w or 0
        if cur_w + space + ww > max_w and #cur_indices > 0 then
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

    local lh_mul = Options.dw_line_height_mul
    local vline_h = (Options.dw_font_size * lh_mul) + Options.dw_vsp
    local entry_h = #vlines * vline_h

    sub.layout_cache = {
        version = FSM.LAYOUT_VERSION,
        entry = {
            sub_idx = -1, -- caller-specific; draw path will overwrite with real index
            vlines = vlines,
            logical_to_visual = logical_to_visual,
            words = tokens,
            height = entry_h
        }
    }
    return sub.layout_cache.entry
end

local function dw_get_word_visual_line(sub, logical_idx)
    local entry = ensure_sub_layout(sub)
    if not entry then return 1, 1 end
    
    local v_idx = entry.logical_to_visual[logical_idx]
    if not v_idx then return 1, 1 end
    for i, vl in ipairs(entry.vlines) do
        for _, idx in ipairs(vl) do
            if idx == v_idx then return i, #entry.vlines end
        end
    end
    return 1, 1
end

-- Returns the logical word index on sub whose OSD x-center is closest to target_x.
-- Falls back to first word if nothing found.
local function dw_closest_word_at_x(sub, target_x, word_only, vl_filter)
    local entry = ensure_sub_layout(sub)
    if not entry then return -1 end
    
    local words = entry.words
    local vlines = entry.vlines
    local visual_to_logical = {}
    for j, t in ipairs(words or {}) do
        if t.logical_idx then visual_to_logical[j] = t.logical_idx end
    end
    
    local space_w = dw_get_str_width(" ")

    local best_logical = nil
    local best_dist = math.huge

    -- For multi-vline subtitles, target_x may sit on any visual row.
    -- We search vlines (optionally filtered) and pick the globally closest word.
    for i, vl_indices in ipairs(vlines) do
        if not vl_filter or i == vl_filter then
            local vl_width = 0
            for k, wi in ipairs(vl_indices) do
                vl_width = vl_width + dw_get_str_width(words[wi])
                if k < #vl_indices and not Options.dw_original_spacing then vl_width = vl_width + space_w end
            end
            local vl_left = 960 - vl_width / 2
            local pos = 0
            for k, wi in ipairs(vl_indices) do
                local ww = dw_get_str_width(words[wi])
                local l_idx = visual_to_logical[wi]
                if l_idx then
                    local valid = false
                    if word_only then
                        valid = words[wi].is_word
                    else
                        valid = not words[wi].text:match("^%s*$")
                    end
                    
                    if valid then
                        local cx = vl_left + pos + ww / 2
                        local dist = math.abs(cx - target_x)
                        if dist < best_dist then
                            best_dist = dist
                            best_logical = l_idx
                        end
                    end
                end
                pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
            end
        end
    end

    return best_logical or (not word_only and get_first_valid_word_idx(sub) or -1)
end


dw_ensure_visible = function(line_idx, paged)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local is_drum_mini = (FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF")
    local win_lines = is_drum_mini and (Options.drum_context_lines * 2 + 1) or Options.dw_lines_visible
    win_lines = math.max(1, math.floor(win_lines or 1))
    local half_win = math.floor(win_lines / 2)
    local configured_scrolloff = is_drum_mini and Options.drum_scrolloff or Options.dw_scrolloff
    local max_margin = math.max(0, math.floor(win_lines / 2) - 1)
    local margin = math.max(0, math.min(math.floor(configured_scrolloff or 0), max_margin))
    
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


local function cmd_dw_line_move(dir, shift, evt)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    if type(evt) == "table" and evt.event == "repeat" and FSM.DW_NAV_ACTIVATION_GUARD_UNTIL
       and mp.get_time() <= FSM.DW_NAV_ACTIVATION_GUARD_UNTIL then
        return
    end

    local state_active_idx = FSM.DW_ACTIVE_LINE
    if (not state_active_idx or state_active_idx == -1) and FSM.ACTIVE_IDX and FSM.ACTIVE_IDX ~= -1 then
        state_active_idx = FSM.ACTIVE_IDX
    end
    
    FSM.DW_FOLLOW_PLAYER = false
    
    -- Recovery: If no cursor line is set (startup/no active sub), snap to active or boundaries
    if FSM.DW_CURSOR_LINE == -1 then
        FSM.DW_CURSOR_LINE = (FSM.DW_ACTIVE_LINE ~= -1) and FSM.DW_ACTIVE_LINE or (dir > 0 and 1 or #subs)

    end
    
    local line_idx = FSM.DW_CURSOR_LINE
    local entered_from_null = (FSM.DW_CURSOR_WORD == -1)

    -- Activation guard: when pointer is hidden during live playback, re-anchor from
    -- current playback state before applying UP/DOWN to avoid stale/boundary grabs.
    if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 and not FSM.BOOK_MODE
       and not mp.get_property_bool("pause") and state_active_idx and state_active_idx ~= -1 then
        line_idx = state_active_idx
        FSM.DW_CURSOR_LINE = line_idx
    end
    
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
    
    -- Intra-subtitle Vertical Navigation: 
    -- If the current subtitle is multi-line, try moving between visual lines first.
    if FSM.DW_CURSOR_WORD ~= -1 then
        local cur_vl, total_vl = dw_get_word_visual_line(subs[line_idx], FSM.DW_CURSOR_WORD)
        local target_vl = cur_vl + dir
        if target_vl >= 1 and target_vl <= total_vl then
            local w = dw_closest_word_at_x(subs[line_idx], FSM.DW_CURSOR_X, true, target_vl)
            if w ~= -1 then
                FSM.DW_CURSOR_WORD = w
                return
            end
        end
    end

    -- Scan for the target line that contains a valid word.
    -- If no word is currently selected (e.g. after Esc), we first try to land on the CURRENT line.
    local start_scan_line = line_idx
    if FSM.DW_CURSOR_WORD ~= -1 then
        start_scan_line = start_scan_line + dir
    end

    for l = start_scan_line, (dir > 0 and #subs or 1), dir do
        local target_vl = nil
        -- Entering a NEW subtitle OR re-activating after Esc: land on appropriate edge
        if l ~= line_idx or FSM.DW_CURSOR_WORD == -1 then
            if dir > 0 then
                target_vl = 1 -- Entry from top: land on first visual line
            else
                -- Entry from bottom: land on last visual line
                local entry = subs[l].layout_cache and subs[l].layout_cache.entry
                target_vl = entry and #entry.vlines or 1
            end
        end

        local w = dw_closest_word_at_x(subs[l], FSM.DW_CURSOR_X, true, target_vl)
        if w ~= -1 then
            FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD = l, w
            break
        end
    end

    if not shift then
        FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD = -1, -1
    end
    
    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    dw_ensure_visible(FSM.DW_CURSOR_LINE, false)

    if entered_from_null and FSM.DW_CURSOR_WORD ~= -1 then
        FSM.DW_NAV_ACTIVATION_GUARD_UNTIL = mp.get_time() + 0.12
    end
end

local function cmd_dw_word_move(dir, shift, evt)
    Diagnostic.info(string.format("cmd_dw_word_move(dir=%s, shift=%s) current_line=%s current_word=%s active_line=%s", tostring(dir), tostring(shift), tostring(FSM.DW_CURSOR_LINE), tostring(FSM.DW_CURSOR_WORD), tostring(FSM.DW_ACTIVE_LINE)))
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    if type(evt) == "table" and evt.event == "repeat" and FSM.DW_NAV_ACTIVATION_GUARD_UNTIL
       and mp.get_time() <= FSM.DW_NAV_ACTIVATION_GUARD_UNTIL then
        return
    end

    local state_active_idx = FSM.DW_ACTIVE_LINE
    if (not state_active_idx or state_active_idx == -1) and FSM.ACTIVE_IDX and FSM.ACTIVE_IDX ~= -1 then
        state_active_idx = FSM.ACTIVE_IDX
    end
    
    FSM.DW_FOLLOW_PLAYER = false
    
    local line_idx = FSM.DW_CURSOR_LINE
    local entered_from_null = (FSM.DW_CURSOR_WORD == -1)

    -- Activation guard parity with UP/DOWN: when pointer is hidden during live playback,
    -- re-anchor from current playback state before entering the line with LEFT/RIGHT.
    if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 and not FSM.BOOK_MODE
       and not mp.get_property_bool("pause") and state_active_idx and state_active_idx ~= -1 then
        line_idx = state_active_idx
        FSM.DW_CURSOR_LINE = line_idx
    end
    
    -- Recovery: If no cursor line is set (e.g. at startup or no active sub), 
    -- try to snap to the active line or the first/last sub.
    if line_idx == -1 then
        line_idx = (FSM.DW_ACTIVE_LINE ~= -1) and FSM.DW_ACTIVE_LINE or (dir > 0 and 1 or #subs)
        FSM.DW_CURSOR_LINE = line_idx
    end

    local raw_sub = subs[line_idx]
    if not raw_sub then return end
    
    local tokens = get_sub_tokens(raw_sub, true)
    
    -- logical_tokens contains all potential landing spots for the current mode
    local logical_tokens = {}
    for i, t in ipairs(tokens) do
        if t.logical_idx then
            -- Requirement: Do not land on invisible spaces (pure whitespace)
            if not t.text:match("^%s*$") then
                table.insert(logical_tokens, t)
            end
        end
    end
    
    if #logical_tokens == 0 then
        FSM.DW_CURSOR_LINE = math.max(1, math.min(#subs, line_idx + (dir > 0 and 1 or -1)))
        FSM.DW_CURSOR_WORD = 1
        FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE])
        if entered_from_null and FSM.DW_CURSOR_WORD ~= -1 then
            FSM.DW_NAV_ACTIVATION_GUARD_UNTIL = mp.get_time() + 0.12
        end
        return
    end

    -- Capture anchor before moving if shift is held and no anchor exists
    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD ~= -1 and FSM.DW_CURSOR_WORD or (dir > 0 and logical_tokens[1].logical_idx or logical_tokens[#logical_tokens].logical_idx)
    end

    local target_token = nil
    local current_idx = -1
    for i, t in ipairs(logical_tokens) do
        if logical_cmp(t.logical_idx, FSM.DW_CURSOR_WORD) then
            current_idx = i
            break
        end
    end
    
    if current_idx ~= -1 then
        -- We are on a token valid for the current mode, just step
        local next_idx = current_idx + dir
        if next_idx >= 1 and next_idx <= #logical_tokens then
            target_token = logical_tokens[next_idx]
        end
    elseif FSM.DW_CURSOR_WORD == -1 then
        -- Activation: Nothing selected (e.g. after Esc), RIGHT enters at start, LEFT enters at end of current line
        target_token = (dir > 0) and logical_tokens[1] or logical_tokens[#logical_tokens]
    else
        -- Transition: We are on a symbol (fractional) but moving in word-only mode (no shift)
        if dir > 0 then
            for _, t in ipairs(logical_tokens) do
                if t.logical_idx > FSM.DW_CURSOR_WORD + L_EPSILON then
                    target_token = t
                    break
                end
            end
        else
            for i = #logical_tokens, 1, -1 do
                local t = logical_tokens[i]
                if t.logical_idx < FSM.DW_CURSOR_WORD - L_EPSILON then
                    target_token = t
                    break
                end
            end
        end
    end

    if target_token then
        FSM.DW_CURSOR_WORD = target_token.logical_idx
    else
        -- Line Jump
        local next_line = line_idx + (dir > 0 and 1 or -1)
        if next_line >= 1 and next_line <= #subs then
            FSM.DW_CURSOR_LINE = next_line
            local next_tokens = get_sub_tokens(subs[next_line], true)
            local next_logical = {}
            for _, t in ipairs(next_tokens) do
                if t.logical_idx then
                    if not t.text:match("^%s*$") then
                        table.insert(next_logical, t)
                    end
                end
            end
            if #next_logical > 0 then
                FSM.DW_CURSOR_WORD = (dir > 0) and next_logical[1].logical_idx or next_logical[#next_logical].logical_idx
            else
                FSM.DW_CURSOR_WORD = 1
            end
        end
    end

    
    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE])
    dw_ensure_visible(FSM.DW_CURSOR_LINE, false)

    if not shift then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    end

    if entered_from_null and FSM.DW_CURSOR_WORD ~= -1 then
        FSM.DW_NAV_ACTIVATION_GUARD_UNTIL = mp.get_time() + 0.12
    end
end


local function cmd_replay_sub()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end
    
    local is_paused = mp.get_property_bool("pause")

    -- [v1.58.48] Sticky Hold Workaround for Hardware Ghosting
    -- If 's' is pressed, the keyboard matrix might send a fake 'Space UP' event just before 's' DOWN.
    -- If Space was held, or released within the last 300ms, we assume they are still intending to hold it.
    local was_holding_space = (FSM.SPACEBAR == "HOLDING") or 
                              (FSM.SPACEBAR == "IDLE" and FSM.space_up_time and (mp.get_time() - FSM.space_up_time) < 0.3)
    
    if was_holding_space then
        FSM.SPACEBAR = "HOLDING" -- Force restore state
        FSM.GHOST_HOLD_EXPIRY = mp.get_time() + 2.0 -- 2 second safety window for desync recovery
    end

    -- [v1.58.49] Fixed Window Replay (Subtitle Independent)
    -- As per user request: "get rid of the boundaries of subtitles altogether and leave only the range of the track"
    local replay_start = math.max(0, time_pos - Options.replay_ms/1000)
    local replay_end = time_pos
    local subs = Tracks.pri.subs
    local current_idx = -1
    local replay_start_idx = -1
    if subs and #subs > 0 then
        current_idx = get_center_index(subs, time_pos)
        replay_start_idx = get_center_index(subs, replay_start)
    end
    local is_cross_card_replay = (current_idx ~= -1 and replay_start_idx ~= -1 and current_idx ~= replay_start_idx)
    local sec_subs = Tracks.sec.subs
    local sec_replay_start_idx = (sec_subs and #sec_subs > 0) and get_center_index(sec_subs, replay_start) or -1

    if FSM.AUTOPAUSE == "OFF" then
        -- Autopause OFF: "Flashback" Replay (Finite Segment)
        -- No toggling: each press restarts the replay window
        FSM.LOOP_MODE = "ON"
        FSM.LOOP_START = replay_start
        FSM.LOOP_END = replay_end
        FSM.LOOP_ARMED = false
        FSM.IGNORE_NEXT_JUMP = true
        FSM.REPLAY_REMAINING = Options.replay_count
        if replay_start_idx ~= -1 then
            FSM.ACTIVE_IDX = replay_start_idx
        end
        if sec_replay_start_idx ~= -1 then
            FSM.SEC_ACTIVE_IDX = sec_replay_start_idx
        end
        
        mp.commandv("seek", replay_start, "absolute+exact")
        if is_paused then mp.set_property_bool("pause", false) end
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
        FSM.REWIND_TRANSIT_CROSS_CARD = false
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
        local x_str = (Options.replay_count > 1) and (" x" .. Options.replay_count) or ""
        local template = Options.replay_msg_format
        local msg = template:gsub("%%m", tostring(Options.replay_ms))
                            :gsub("%%s", tostring(Options.replay_ms / 1000))
                            :gsub("%%c", tostring(Options.replay_count))
                            :gsub("%%x", x_str)
        show_osd(msg)
    else
        -- Autopause ON Mode: Immediate Replay (Fixed Segment)
        FSM.LOOP_MODE = "OFF"
        FSM.IGNORE_NEXT_JUMP = true
        FSM.last_paused_sub_end = nil
        FSM.REPLAY_REMAINING = Options.replay_count
        FSM.SCHEDULED_REPLAY_START = replay_start
        FSM.SCHEDULED_REPLAY_END = replay_end
        if replay_start_idx ~= -1 then
            FSM.ACTIVE_IDX = replay_start_idx
        end
        if sec_replay_start_idx ~= -1 then
            FSM.SEC_ACTIVE_IDX = sec_replay_start_idx
        end
        
        mp.commandv("seek", replay_start, "absolute+exact")
        if is_paused then mp.set_property_bool("pause", false) end
        if is_cross_card_replay then
            FSM.TIMESEEK_INHIBIT_UNTIL = time_pos
            FSM.REWIND_START_IDX = current_idx
            FSM.REWIND_TRANSIT_CROSS_CARD = true
        else
            FSM.TIMESEEK_INHIBIT_UNTIL = nil
            FSM.REWIND_START_IDX = nil
            FSM.REWIND_TRANSIT_CROSS_CARD = false
        end
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
        local x_str = (Options.replay_count > 1) and (" (x" .. Options.replay_count .. ")") or ""
        local template = Options.replay_on_msg_format
        local msg = template:gsub("%%m", tostring(Options.replay_ms))
                            :gsub("%%s", tostring(Options.replay_ms / 1000))
                            :gsub("%%c", tostring(Options.replay_count))
                            :gsub("%%x", x_str)
        show_osd(msg)
    end
end

local function cmd_dw_seek_selected()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    if FSM.DW_CURSOR_LINE > 0 and FSM.DW_CURSOR_LINE <= #subs then
        local sub = subs[FSM.DW_CURSOR_LINE]
        if sub and sub.start_time then
            -- [v1.58.51] Intentional Focus Handover
            FSM.IGNORE_NEXT_JUMP = true
            FSM.ACTIVE_IDX = FSM.DW_CURSOR_LINE
            if #Tracks.sec.subs > 0 then FSM.SEC_ACTIVE_IDX = math.min(FSM.DW_CURSOR_LINE, #Tracks.sec.subs) end
            FSM.JUST_JERKED_TO = -1
            FSM.TIMESEEK_INHIBIT_UNTIL = nil
            FSM.REWIND_TRANSIT_CROSS_CARD = false
            FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown

            local s, _ = get_effective_boundaries(Tracks.pri.subs, sub, FSM.DW_CURSOR_LINE)
            mp.commandv("seek", s, "absolute+exact")
            FSM.last_paused_sub_end = nil
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
    
    -- [v1.58.51] Intentional Focus Handover
    -- When manually seeking, we MUST ignore the padding boundaries of the current index
    -- to prevent "Magnetic Snapping" back to the previous line.
    FSM.IGNORE_NEXT_JUMP = true
    FSM.JUST_JERKED_TO = -1
    FSM.TIMESEEK_INHIBIT_UNTIL = nil
    FSM.REWIND_TRANSIT_CROSS_CARD = false
    FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown -- Settle period for smart logic
    
    local current_idx = get_center_index(subs, time_pos)
    if current_idx == -1 and (not FSM.ACTIVE_IDX or FSM.ACTIVE_IDX == -1) then return end
    
    local base_idx = current_idx
    if FSM.ACTIVE_IDX and FSM.ACTIVE_IDX ~= -1 and subs[FSM.ACTIVE_IDX] then
        base_idx = FSM.ACTIVE_IDX
    end
    if FSM.DW_SEEKING_MANUALLY and FSM.DW_SEEK_TARGET ~= -1 then
        base_idx = FSM.DW_SEEK_TARGET
    end
    
    
    local target_idx = ((base_idx + dir - 1) % #subs) + 1
    local wrapped_msg = nil
    if dir > 0 and target_idx < base_idx then
        wrapped_msg = "Wrapped to START"
    elseif dir < 0 and target_idx > base_idx then
        wrapped_msg = "Wrapped to END"
    end
    
    FSM.DW_SEEK_TARGET = target_idx
    if wrapped_msg then show_osd(wrapped_msg) end
    local sub = subs[target_idx]
    if sub and sub.start_time then
        local s, _ = get_effective_boundaries(Tracks.pri.subs, sub, target_idx)
        mp.commandv("seek", math.max(0, s), "absolute+exact")
        FSM.ACTIVE_IDX = target_idx
        if #Tracks.sec.subs > 0 then FSM.SEC_ACTIVE_IDX = math.min(target_idx, #Tracks.sec.subs) end
        FSM.last_paused_sub_end = nil
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        
        if FSM.DW_ANCHOR_LINE == -1 then
            if not FSM.BOOK_MODE then
                FSM.DW_CURSOR_LINE = target_idx
                FSM.DW_CURSOR_WORD = -1
                FSM.DW_CURSOR_X = nil
            elseif FSM.DW_CURSOR_WORD == -1 then
                -- In Book Mode, preserve intentional pointer selections, but when pointer is
                -- already cleared keep the standing line synchronized with manual a/d seeks.
                FSM.DW_CURSOR_LINE = target_idx
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

local function cmd_seek_time(dir)
    local now = mp.get_time()
    local delta = dir * Options.seek_time_delta
    
    -- YouTube-style Accumulator logic:
    -- Accumulate ONLY if within the time window AND the direction matches.
    -- Otherwise, start a new session.
    local same_dir = (dir > 0 and FSM.SEEK_ACCUMULATOR > 0) or (dir < 0 and FSM.SEEK_ACCUMULATOR < 0)
    -- [20260510193230] Extended accumulator window for backward seeks to allow more clicks to accumulate.
    local accumulator_window = (dir < 0) and (Options.seek_osd_duration * 2) or Options.seek_osd_duration
    if now < FSM.SEEK_LAST_TIME + accumulator_window and same_dir then
        FSM.SEEK_ACCUMULATOR = FSM.SEEK_ACCUMULATOR + delta
        FSM.SEEK_PRESS_COUNT = FSM.SEEK_PRESS_COUNT + 1
    else
        FSM.SEEK_ACCUMULATOR = delta
        FSM.SEEK_PRESS_COUNT = 1
    end
    FSM.SEEK_LAST_TIME = now
    
    FSM.IGNORE_NEXT_JUMP = true
    FSM.JUST_JERKED_TO = -1
    FSM.MANUAL_NAV_COOLDOWN = now + Options.nav_cooldown

    -- [v1.58.54] Time-based seek (Shift+A/D) overrides repeat/loop state.
    -- The user is manually scrubbing the tape; active loops/replays should not survive the seek.
    FSM.LOOP_MODE = "OFF"
    FSM.REPLAY_REMAINING = 0
    FSM.SCHEDULED_REPLAY_START = nil
    FSM.SCHEDULED_REPLAY_END = nil
    FSM.last_paused_sub_end = nil  -- Allow autopause to re-arm at the correct boundary after rewind.

    -- [v1.58.54] Suppress autopause at subtitles encountered during backward rewind transit.
    -- Autopause is inhibited until playback naturally returns past the pre-seek position.
    -- [20260510193230] Track rewind start index to distinguish within-subtitle vs cross-subtitle rewind.
    local current_pos = mp.get_property_number("time-pos") or 0
    local target_pos = math.max(0, current_pos + delta)
    local subs = Tracks.pri.subs
    local current_idx = (subs and #subs > 0) and get_center_index(subs, current_pos) or -1
    local target_idx = (subs and #subs > 0) and get_center_index(subs, target_pos) or -1
    local sec_subs = Tracks.sec.subs
    local sec_target_idx = (sec_subs and #sec_subs > 0) and get_center_index(sec_subs, target_pos) or -1
    local is_cross_card_seek = (current_idx ~= -1 and target_idx ~= -1 and current_idx ~= target_idx)

    -- Forward seek clears transit inhibit immediately.
    if delta > 0 then
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
        FSM.REWIND_TRANSIT_CROSS_CARD = false
    else
        -- Backward seek always contributes to sentinel (legacy contract + tests).
        -- Cross-card classification is tracked separately for suppression gating.
        FSM.TIMESEEK_INHIBIT_UNTIL = math.max(FSM.TIMESEEK_INHIBIT_UNTIL or current_pos, current_pos)
        FSM.REWIND_START_IDX = current_idx
        FSM.REWIND_TRANSIT_CROSS_CARD = is_cross_card_seek
    end

    -- Immediate anchor during Shift+A/D to minimize upper-track perceived lag
    -- before natural sentinel scan catches up after cooldown.
    if target_idx ~= -1 then
        FSM.ACTIVE_IDX = target_idx
    end
    if sec_target_idx ~= -1 then
        FSM.SEC_ACTIVE_IDX = sec_target_idx
    end

    mp.commandv("seek", delta, "relative+exact")
    
    -- Display logic: 
    -- Use templates to format the OSD message.
    -- %p = instant prefix, %v = instant value
    -- %P = accumulator prefix, %V = accumulator value
    local prefix = (delta > 0) and "+" or "-"
    local delta_val = math.abs(delta)
    local delta_str = (delta_val % 1 == 0) and tostring(math.floor(delta_val)) or string.format("%.1f", delta_val)
    
    local acc_prefix = (FSM.SEEK_ACCUMULATOR > 0) and "+" or "-"
    local acc_val = math.abs(FSM.SEEK_ACCUMULATOR)
    if acc_val < 0.001 then acc_val = 0; acc_prefix = "" end
    local acc_str = (acc_val % 1 == 0) and tostring(math.floor(acc_val)) or string.format("%.1f", acc_val)
    
    local template = (Options.seek_show_accumulator and FSM.SEEK_PRESS_COUNT >= 1) 
        and Options.seek_msg_cumulative_format 
        or Options.seek_msg_format
    
    -- On first press of an accumulator session, we might want to use the standard template
    -- but the user specified +2 -> +4 logic, so we use cumulative_format if accumulator is enabled.
    -- To allow "%p%v (%P%V)" style, we provide all variables to both.
    local msg = template:gsub("%%p", prefix):gsub("%%v", delta_str):gsub("%%P", acc_prefix):gsub("%%V", acc_str)
    
    local alignment = (delta > 0) and 6 or 4
    show_seek_osd(msg, alignment)
end


local function cmd_seek_with_repeat(dir, table)
    if not table or not table.event then 
        -- Fallback for simple calls if any
        cmd_dw_seek_delta(dir)
        return 
    end

    if table.event == "press" then
        -- Synthetic event from script-binding or input.conf trigger (no down/up pair).
        cmd_dw_seek_delta(dir)
    elseif table.event == "down" then
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
        {key = "LEFT", name = "dw-word-left", fn = nav(function(t) cmd_dw_word_move(-1, false, t) end, "LEFT"), complex = true, repeatable = true},
        {key = "RIGHT", name = "dw-word-right", fn = nav(function(t) cmd_dw_word_move(1, false, t) end, "RIGHT"), complex = true, repeatable = true},
        {key = "UP", name = "dw-line-up", fn = nav(function(t) cmd_dw_line_move(-1, false, t) end, "UP"), complex = true, repeatable = true},
        {key = "DOWN", name = "dw-line-down", fn = nav(function(t) cmd_dw_line_move(1, false, t) end, "DOWN"), complex = true, repeatable = true},
        {key = "WHEEL_UP", name = "dw-scroll-up", fn = function() cmd_dw_wheel_scroll(-1) end},
        {key = "WHEEL_DOWN", name = "dw-scroll-down", fn = function() cmd_dw_wheel_scroll(1) end},
        {key = Options.dw_key_pair_mod, name = "dw-pair-mod-track", fn = nav(function(t) 
            FSM.DW_CTRL_HELD = (t.event == "down" or t.event == "repeat")
        end, Options.dw_key_pair_mod), complex = true},
        {key = "ЛЕВЫЙ", name = "dw-word-left-ru", fn = nav(function(t) cmd_dw_word_move(-1, false, t) end, "ЛЕВЫЙ"), complex = true, repeatable = true},
        {key = "ПРАВЫЙ", name = "dw-word-right-ru", fn = nav(function(t) cmd_dw_word_move(1, false, t) end, "ПРАВЫЙ"), complex = true, repeatable = true},
        {key = "ВВЕРХ", name = "dw-line-up-ru", fn = nav(function(t) cmd_dw_line_move(-1, false, t) end, "ВВЕРХ"), complex = true, repeatable = true},
        {key = "ВНИЗ", name = "dw-line-down-ru", fn = nav(function(t) cmd_dw_line_move(1, false, t) end, "ВНИЗ"), complex = true, repeatable = true},
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
        local expanded_keys = expand_ru_keys(key_string, base_name)
        for _, key in ipairs(expanded_keys) do
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
    parse_and_collect(Options.dw_key_copy, "dw-copy", nil, function() cmd_dw_copy("none") end, false)
    parse_and_collect(Options.key_copy_popup, "dw-copy-popup", nil, function() cmd_dw_copy("side") end, false)
    parse_and_collect(Options.key_copy_main, "dw-copy-main", nil, function() cmd_dw_copy("main") end, false)
    parse_and_collect(Options.dw_key_seek, "dw-seek", nil, function() cmd_dw_seek_selected() end, false)
    -- Note: replay handled via global named 'replay-subtitle' binding (no DW-local duplicate)
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
        if active and k.key and is_valid_mpv_key(k.key) then 
            if not (k.key == "Ctrl" or k.key == "Shift" or k.key == "Alt" or k.key == "Meta") then
                local wrapped_fn = function(t)
                    -- For repeatable complex navigation bindings, ignore key-up events
                    -- so a single physical press does not trigger an extra move on release.
                    if k.repeatable and t and t.event == "up" then
                        return
                    end
                    if t and t.event == "down" then

                    end
                    return k.fn(t)
                end

                if k.complex then
                    local opts = {complex = true}
                    if k.repeatable then opts.repeatable = true end
                    mp.add_forced_key_binding(k.key, k.name, wrapped_fn, opts)
                else
                    local settings = nil
                    if k.key:match("LEFT") or k.key:match("RIGHT") or k.key:match("UP") or k.key:match("DOWN") 
                       or k.key:match("ЛЕВЫЙ") or k.key:match("ПРАВЫЙ") or k.key:match("ВВЕРХ") or k.key:match("ВНИЗ")
                       or k.key == "ENTER" or k.key == "KP_ENTER" then
                        settings = "repeatable"
                    end
                    mp.add_forced_key_binding(k.key, k.name, wrapped_fn, settings)
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
            clear_tooltip_overlay("bindings-disabled")
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

local function set_clipboard(text, mode)
    if text and text ~= "" then
        mp.set_property("user-data/kardenwort/last_clipboard", text)
    end
    -- [v1.58.32] Native property is unreliable on some Windows MPV builds for system-wide sync.
    -- We skip it on Windows to ensure PowerShell (which handles retries/encoding) is used.
    local platform = package.config:sub(1,1)
    if platform ~= "\\" then
        local success = pcall(function() mp.set_property("clipboard", text) end)
        if success then return end
    end
    if platform == "\\" then
        local safe_txt = text:gsub("'", "''")
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; for ($i=0; $i -lt %d; $i++) { try { Set-Clipboard -Value '%s' -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds %d } }", Options.win_clipboard_retries, safe_txt, Options.win_clipboard_retry_delay)
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

    -- [v1.58.32] Optional explicit trigger for GoldenDict scan popup.
    -- This bypasses AHK polling latency by directly notifying the dictionary tool.
    -- [v1.58.36] Robust GoldenDict trigger (Improved layout/modifier stability)
    -- [v1.58.38] Professional Layout-Independent Trigger (VK-based)
    if Options.gd_trigger_enabled == "yes" and platform == "\\" and (mode == "side" or mode == "main") then
        local user_hotkey = (mode == "main") and Options.gd_hotkey_main or Options.gd_hotkey_popup
        -- [v1.58.40] Expanded VK mapping for layout-independent triggers
        local vk_codes = {
            ctrl = 0x11, alt = 0x12, shift = 0x10, win = 0x5B,
            a = 0x41, b = 0x42, c = 0x43, d = 0x44, e = 0x45, f = 0x46, g = 0x47, h = 0x48, i = 0x49,
            j = 0x4A, k = 0x4B, l = 0x4C, m = 0x4D, n = 0x4E, o = 0x4F, p = 0x50, q = 0x51, r = 0x52,
            s = 0x53, t = 0x54, u = 0x55, v = 0x56, w = 0x57, x = 0x58, y = 0x59, z = 0x5A,
            ["0"] = 0x30, ["1"] = 0x31, ["2"] = 0x32, ["3"] = 0x33, ["4"] = 0x34,
            ["5"] = 0x35, ["6"] = 0x36, ["7"] = 0x37, ["8"] = 0x38, ["9"] = 0x39,
            f1 = 0x70, f2 = 0x71, f3 = 0x72, f4 = 0x73, f5 = 0x74, f6 = 0x75,
            f7 = 0x76, f8 = 0x77, f9 = 0x78, f10 = 0x79, f11 = 0x7A, f12 = 0x7B,
            -- Cyrillic equivalents (ЙЦУКЕН)
            ["й"] = 0x51, ["ц"] = 0x57, ["у"] = 0x45, ["к"] = 0x52, ["е"] = 0x54, ["н"] = 0x59, ["г"] = 0x55, ["ш"] = 0x49, ["щ"] = 0x4F, ["з"] = 0x50,
            ["ф"] = 0x41, ["ы"] = 0x53, ["в"] = 0x44, ["а"] = 0x46, ["п"] = 0x47, ["р"] = 0x48, ["о"] = 0x4A, ["л"] = 0x4B, ["д"] = 0x4C,
            ["я"] = 0x5A, ["ч"] = 0x58, ["с"] = 0x43, ["м"] = 0x56, ["и"] = 0x42, ["т"] = 0x4E, ["ь"] = 0x4D, ["б"] = 0xBC, ["ю"] = 0xBE
        }
        
        local all_events = {}
        for hotkey in user_hotkey:gmatch("[^%s,;]+") do
            local primary = hotkey:lower()
            local events = {}
            local modifiers = { "ctrl", "alt", "shift", "win" }
            
            -- [v1.58.42] Handle implicit shift from uppercase keys (e.g. "Ctrl+Alt+Q")
            local main_key = hotkey:match("[^+]+$")
            local needs_shift = (main_key and #main_key == 1 and main_key:match("%u")) or primary:find("shift")

            for _, mod in ipairs(modifiers) do
                if mod ~= "shift" and primary:find(mod) then 
                    table.insert(events, {vk_codes[mod], 0}) 
                end
            end
            if needs_shift then table.insert(events, {vk_codes.shift, 0}) end
            
            -- Get the main key (the last part)
            local key = main_key:lower()
            if key and vk_codes[key] then
                table.insert(events, {vk_codes[key], 0}) -- Down
                table.insert(events, {vk_codes[key], 2}) -- Up
            end
            
            -- Release modifiers in reverse order
            for i = #events - 1, 1, -1 do
                if events[i][2] == 0 then table.insert(events, {events[i][1], 2}) end
            end
            
            for _, ev in ipairs(events) do table.insert(all_events, ev) end
        end
        
        if #all_events == 0 then return end

        
        -- [v1.58.48] Configurable Trigger Lock (Prevent AHK Recursion)
        local now = mp.get_time()
        if (now - (FSM.LAST_TRIGGER_TIME or 0)) < Options.gd_trigger_lock_duration then
            -- A trigger was recently fired, likely by the user.
            -- Any subsequent ^c from AHK should just update the clipboard without re-triggering.
            return
        end
        FSM.LAST_TRIGGER_TIME = now
        
        -- [v1.58.48] Independent Mode Delays (Popup/Main)
        if Options.gd_trigger_method == "python" then
            local delay = (mode == "main") and Options.python_trigger_delay_main or Options.python_trigger_delay_popup
            local py_cmd = string.format("import ctypes, time; time.sleep(%f); u=ctypes.windll.user32; ", delay)
            for _, ev in ipairs(all_events) do
                py_cmd = py_cmd .. string.format("u.keybd_event(0x%X,0,%d,0); ", ev[1], ev[2])
            end
            mp.command_native_async({
                name = "subprocess",
                args = {Options.python_path, "-c", py_cmd},
                playback_only = false,
                capture_stdout = false, capture_stderr = false
            }, function() end)
        else
            -- Robust VK Injector via PowerShell Add-Type (Default)
            local type_name = "Win32K" .. os.time()
            local signature = '[DllImport(\"user32.dll\")] public static extern void keybd_event(byte b, byte s, uint f, uint e);'
            local script = string.format("$t = Add-Type -MemberDefinition '%s' -Name '%s' -Namespace 'Win32' -PassThru;", signature, type_name)
            
            for _, ev in ipairs(all_events) do
                script = script .. string.format("$t::keybd_event(0x%X,0,%d,0);", ev[1], ev[2])
            end

            
            mp.command_native_async({
                name = "subprocess",
                args = {"powershell", "-NoProfile", "-Command", script},
                playback_only = false,
                capture_stdout = false, capture_stderr = false
            }, function() end)
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

    local function normalize_hl(indices)
        local hl = {}
        if type(indices) ~= "table" then return hl end
        for k, v in pairs(indices) do
            if type(k) == "number" and v == true then
                hl[k] = true
            elseif type(v) == "number" then
                hl[v] = true
            elseif type(k) == "string" and v == true then
                local nk = tonumber(k)
                if nk then hl[nk] = true end
            end
        end
        return hl
    end
    
    for i, sub in ipairs(subs) do
        local score, indices = calculate_match_score(sub.text, query)
        if score > 0 then
            table.insert(scored_results, {idx = i, score = score, hl = normalize_hl(indices)})
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
        table.insert(FSM.SEARCH_RESULTS, {idx = item.idx, text = subs[item.idx].text, hl = item.hl})
    end
end

local function draw_search_ui()
    if not FSM.SEARCH_MODE then return "" end
    
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
    local bord = 0 -- Simplified Search UI (Task 1.3)
    local shad = Options.search_shadow_offset or 0.0
    
    local opacity_hex = calculate_ass_alpha(Options.search_bg_opacity or "60")

    -- [Task 1.1] Process Query first to determine visual line count
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
        
        if cur == #q_table and not has_sel then
            display_query = display_query .. "|"
        end
    end

    -- Calculate visual lines for the query background
    local stripped_query = display_query:gsub("{[^}]+}", "")
    local query_char_tokens = {}
    for c in stripped_query:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(query_char_tokens, {text = c})
    end
    
    local query_vlines = wrap_tokens(query_char_tokens, box_w - padding_x * 2, font_size, font_name, true)
    local query_line_count = math.max(1, #query_vlines)
    
    -- [Task 1.2] Calculate input_box_h dynamically
    local input_box_h = query_line_count * line_height + padding_y * 2
    
    local ass = ""
    -- [Task 1.3] Draw Input Field Backing with dynamic height and synchronized transparency
    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
        box_x, box_y, bord, border_color, bg_color, opacity_hex, opacity_hex, opacity_hex, bg_color, box_w, box_w, input_box_h, input_box_h)
    
    -- Draw Input Text (Task 3.2 Synchronized)
    ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad%g}{\\4a&H%s&}{\\fs%d}{\\c&H%s&} %s\n",
        font_name, box_x + padding_x, box_y + padding_y, shad, opacity_hex, font_size, "FFFFFF", display_query)
        
    -- Draw Results Dropdown
    if #FSM.SEARCH_RESULTS > 0 then
        local max_results_display = 8
        local display_count = math.min(#FSM.SEARCH_RESULTS, max_results_display)
        -- [Task 2.1] results_y is relative to dynamic input_box_h
        local results_y = box_y + input_box_h + 5
        
        -- [Task 2.2/2.3/3.1] Pre-calculate results layout with wrapping
        local results_layout = {}
        local total_results_vlines = 0
        local r_font_size = font_size
        if Options.search_results_font_size then
            if Options.search_results_font_size > 0 then
                r_font_size = Options.search_results_font_size
            elseif Options.search_results_font_size == -1 then
                r_font_size = math.floor(font_size * 0.8)
            end
        end
        local r_line_height = r_font_size * Options.search_line_height_mul

        local start_idx = math.max(1, FSM.SEARCH_SEL_IDX - math.floor(max_results_display / 2))
        if start_idx + max_results_display - 1 > #FSM.SEARCH_RESULTS then
            start_idx = math.max(1, #FSM.SEARCH_RESULTS - max_results_display + 1)
        end
        
        for k = 1, display_count do
            local result_idx = start_idx + k - 1
            if result_idx > #FSM.SEARCH_RESULTS then break end
            
            local result_data = FSM.SEARCH_RESULTS[result_idx]
            local sub_text = Tracks.pri.subs[result_data.idx].text:gsub("\n", " ")
            local raw_t_table = utf8_to_table(sub_text)
            
            -- Truncate for display (v1.58.0 standard)
            if #raw_t_table > 120 then 
                local new_t = {}
                for i = 1, 120 do table.insert(new_t, raw_t_table[i]) end
                sub_text = table.concat(new_t) .. "..."
            end
            
            -- Build tokens and wrap
            local res_tokens = build_word_list_internal(sub_text, true)
            local res_vlines = wrap_tokens(res_tokens, box_w - padding_x * 2, r_font_size, font_name, true)
            
            table.insert(results_layout, {
                data = result_data,
                vlines = res_vlines,
                idx = result_idx,
                tokens = res_tokens
            })
            total_results_vlines = total_results_vlines + #res_vlines
        end

        -- [Task 2.4] Use dynamic results_h
        local results_h = total_results_vlines * r_line_height + padding_y * 2
        
        -- Dropdown Backing with synchronized transparency (Task 1.2)
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, bord, border_color, bg_color, opacity_hex, opacity_hex, opacity_hex, bg_color, box_w, box_w, results_h, results_h)
            
        -- [Task 3.1] Render using cumulative Y offset and populate hit-zones
        FSM.SEARCH_HIT_ZONES = {}
        local current_y = results_y + padding_y
        for _, item in ipairs(results_layout) do
            local result_data = item.data
            local result_idx = item.idx
            local res_vlines = item.vlines
            local res_tokens = item.tokens
            
            local is_selected = (result_idx == FSM.SEARCH_SEL_IDX)
            local base_color = is_selected and Options.search_sel_color or text_color
            local sel_bold = (is_selected and Options.search_sel_bold) and "{\\b1}" or ""
            local sel_bold_end = (is_selected and Options.search_sel_bold) and "{\\b0}" or ""
            
            -- Construct highlighted string for each visual line
            local hit_color = is_selected and (Options.search_query_hit_color or "FFFFFF") or Options.search_hit_color
            local hit_bold = Options.search_hit_bold and "{\\b1}" or ""
            local hit_bold_end = Options.search_hit_bold and "{\\b0}" or ""

            local token_char_start = 1
            for _, line_indices in ipairs(res_vlines) do
                local display_text = ""
                for ti, token_idx in ipairs(line_indices) do
                    local t = res_tokens[token_idx]
                    local t_table = utf8_to_table(t.text)
                    for ci = 1, #t_table do
                        local global_ci = token_char_start + ci - 1
                        local is_hit = result_data.hl and result_data.hl[global_ci]
                        if is_hit then
                            display_text = display_text .. string.format("%s{\\c&H%s&}%s%s{\\c&H%s&}", hit_bold, hit_color, t_table[ci], hit_bold_end, base_color)
                        else
                            display_text = display_text .. t_table[ci]
                        end
                    end
                    token_char_start = token_char_start + #t_table
                end
                
                -- [Task 3.1] Populate hit-zones for this visual line
                table.insert(FSM.SEARCH_HIT_ZONES, {
                    result_idx = result_idx,
                    y_top = current_y,
                    y_bottom = current_y + r_line_height
                })

                -- [Task 3.2] Render at current_y
                ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&H%s&}{\\fs%d}{\\c&H%s&} %s%s%s\n",
                    font_name, box_x + padding_x, current_y, opacity_hex, r_font_size, base_color, sel_bold, display_text, sel_bold_end)
                
                current_y = current_y + r_line_height
            end
        end
    elseif FSM.SEARCH_QUERY ~= "" then
        -- "No results"
        local results_h = line_height + padding_y * 2
        local results_y = box_y + input_box_h + 5
        
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, bord, border_color, bg_color, opacity_hex, opacity_hex, opacity_hex, bg_color, box_w, box_w, results_h, results_h)
            
        local r_font_size = font_size
        if Options.search_results_font_size then
            if Options.search_results_font_size > 0 then
                r_font_size = Options.search_results_font_size
            elseif Options.search_results_font_size == -1 then
                r_font_size = font_size * 0.8
            end
        end
        ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&H%s&}{\\fs%d}{\\c&H%s&} No results found.\n",
            font_name, box_x + padding_x, results_y + padding_y, opacity_hex, r_font_size, "999999")
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

local SEARCH_INPUT_CHARS = "abcdefghijklmnopqrstuvwxyz1234567890-=[]\\;',./ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+{}|:\"<>?абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯäöüßÄÖÜẞ "
local SEARCH_GERMAN_CHARS = { "ä", "ö", "ü", "ß", "Ä", "Ö", "Ü", "ẞ" }

local function utf8_iter_chars(str)
    return string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*")
end

local function search_binding_name_for_char(ch)
    return "search-char-" .. ((ch == " ") and "SPACE" or ch)
end

local function verify_search_german_whitelist()
    for _, ch in ipairs(SEARCH_GERMAN_CHARS) do
        if not SEARCH_INPUT_CHARS:find(ch, 1, true) then
            Diagnostic.error("Search char whitelist missing required German key: " .. ch)
        end
    end
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
        verify_search_german_whitelist()
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
        
        FSM.SEARCH_CHAR_BINDINGS = {}
        for ch in utf8_iter_chars(SEARCH_INPUT_CHARS) do
            local key_name = (ch == " ") and "SPACE" or ch
            local binding_name = search_binding_name_for_char(ch)
            FSM.SEARCH_CHAR_BINDINGS[binding_name] = true
            
            mp.add_forced_key_binding(key_name, binding_name, function()
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
        for _, ch in ipairs(SEARCH_GERMAN_CHARS) do
            local binding_name = search_binding_name_for_char(ch)
            if not FSM.SEARCH_CHAR_BINDINGS[binding_name] then
                Diagnostic.error("Search binding registry missing German key binding: " .. ch)
            end
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
                -- Interaction shield (Task 3.1 Hardening)
                if FSM.DW_MOUSE_LOCK_UNTIL and mp.get_time() < FSM.DW_MOUSE_LOCK_UNTIL then return end
                
                if #FSM.SEARCH_RESULTS == 0 or not FSM.SEARCH_HIT_ZONES then return end
                
                local osd_x, osd_y = dw_get_mouse_osd()
                
                -- Global constraints (Task 3.1 Synchronized)
                local box_w = 1200
                local box_x = 960 - (box_w / 2)
                
                if osd_x < box_x or osd_x > box_x + box_w then return end

                local found_idx = -1
                for _, zone in ipairs(FSM.SEARCH_HIT_ZONES) do
                    if osd_y >= zone.y_top and osd_y <= zone.y_bottom then
                        found_idx = zone.result_idx
                        break
                    end
                end

                if found_idx ~= -1 then
                    FSM.SEARCH_SEL_IDX = found_idx
                    
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
        bind(Options.search_key_click, "mouse-click", search_mouse_click, {complex = true})
        
        render_search()
    else
        FSM.SEARCH_MODE = false
        manage_ui_border_override(false)

        -- Remove exactly the same search char bindings that were registered.
        for name, _ in pairs(FSM.SEARCH_CHAR_BINDINGS or {}) do
            mp.remove_key_binding(name)
        end
        -- Defensive sweep: if runtime state was reset, still remove by canonical character list.
        for ch in utf8_iter_chars(SEARCH_INPUT_CHARS) do
            mp.remove_key_binding(search_binding_name_for_char(ch))
        end
        FSM.SEARCH_CHAR_BINDINGS = {}
        
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
        
        update_interactive_bindings()
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

        -- Update state immediately for responsiveness
        FSM.DRUM_WINDOW = "DOCKED"
        clear_tooltip_overlay("drum-window-open-transition")
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
        end
        
        -- Always sync view center to cursor line on opening
        FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
        
        FSM.DW_SEEKING_MANUALLY = false
        FSM.DW_SEEK_TARGET = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        -- [20260501163905] DO NOT reset CURSOR_WORD/ANCHOR here to allow cross-mode synchronization
        FSM.DW_FOLLOW_PLAYER = true
        
        if not FSM.SEARCH_MODE then
            update_interactive_bindings()
        end

        -- Explicitly trigger first render for instant appearance
        if FSM.DRUM_WINDOW == "DOCKED" then
            local active_idx = get_center_index(Tracks.pri.subs, time_pos or 0)
            tick_dw(time_pos or 0, active_idx)
            show_osd("Drum Window: ON")
        end
    else

        -- Update state immediately
        FSM.DRUM_WINDOW = "OFF"
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("drum-window-close-transition")
        manage_ui_border_override(false)

        if not FSM.SEARCH_MODE then
            update_interactive_bindings()
        end
        dw_osd.data = ""
        dw_osd:update()

        -- Restore subtitle visibility
        FSM.native_sub_vis = FSM.DW_SAVED_SUB_VIS
        show_osd("Drum Window: OFF")
    end
    end, debug.traceback)
    if not ok then
        -- Roll back FSM state to prevent phantom window open/close on next toggle
        FSM.DRUM_WINDOW = prev_drum_window
        Diagnostic.error("Drum Window Toggle: " .. tostring(err))
        show_osd("kardenwort ERROR: " .. tostring(err):sub(1, 100))
    end

end

function toggle_book_mode()
    FSM.BOOK_MODE = not FSM.BOOK_MODE
    if FSM.BOOK_MODE then
        -- Keep DM workflows in-place: only auto-open DW when neither DM nor DW is active.
        if FSM.DRUM_WINDOW == "OFF" and FSM.DRUM ~= "ON" then
            cmd_toggle_drum_window()
        end
        show_osd("Book Mode: ON")
    else
        show_osd("Book Mode: OFF")
    end
end




local function get_clipboard_text_smart(time_pos, line_idx)
    local cl = line_idx or FSM.DW_CURSOR_LINE
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cw = FSM.DW_CURSOR_WORD

    -- 0. Smart Fallback / Focus
    if cl == -1 then
        if FSM.BOOK_MODE and FSM.DW_FOLLOW_PLAYER and al == -1 and cw == -1 then
            cl = FSM.DW_ACTIVE_LINE
        elseif time_pos then
            cl = get_center_index(Tracks.pri.subs, time_pos)
        else
            cl = FSM.DW_ACTIVE_LINE
        end
    end
    if cl == -1 then return nil, false end

    -- 1. Selection Priority (Pink Set > Yellow Range > Yellow Pointer)
    -- [v1.58.51] Explicit priority allows user to regulate behavior via Esc stages.
    
    -- Stage 1: Pink Set (Multi-word Selection via Ctrl+Click)
    if #FSM.DW_CTRL_PENDING_LIST > 0 then
        return prepare_export_text({ type = "SET", members = FSM.DW_CTRL_PENDING_LIST }, { 
            copy_mode = FSM.COPY_MODE, 
            filter_russian = Options.copy_filter_russian 
        }), false
    end

    -- Stage 2 & 3: Yellow Selection (Range or Point)
    local p1_l, p1_w, p2_l, p2_w = get_dw_selection_bounds()
    if p1_l or cw ~= -1 then
        local params = p1_l and { type = "RANGE", p1_l = p1_l, p1_w = p1_w, p2_l = p2_l, p2_w = p2_w }
                             or { type = "POINT", line = cl, word = cw }
        
        return prepare_export_text(params, { 
            copy_mode = FSM.COPY_MODE, 
            filter_russian = Options.copy_filter_russian 
        }), false
    end

    -- 2. Context Priority
    if FSM.COPY_CONTEXT == "ON" then
        local ctx = get_copy_context_text(time_pos, cl)
        if ctx and ctx ~= "" then
            return ctx:gsub("{[^}]+}", ""):gsub("\n", " "), true
        end
    end

    -- 3. Standard Fallback
    return prepare_export_text({ type = "POINT", line = cl }, { 
        copy_mode = FSM.COPY_MODE, 
        filter_russian = Options.copy_filter_russian 
    }), false
end


function cmd_dw_copy(mode)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local final_text, is_context = get_clipboard_text_smart()
    
    if final_text and final_text ~= "" then
        set_clipboard(final_text, mode)
        local now = mp.get_time()
        if (now - (FSM.LAST_OSD_TIME or 0)) > Options.copy_osd_cooldown then
            local label = is_context and "Context" or "DW"
            show_osd(label .. " Copied: " .. final_text:sub(1, 40) .. (#final_text > 40 and "..." or ""))
            FSM.LAST_OSD_TIME = now
        end
    end
end


local function cmd_toggle_sub_vis()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
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
        -- [20260509192327] Dismiss tooltip immediately when subs are hidden.
        -- is_osd_tooltip_mode_eligible() checks native_sub_vis, so the tooltip
        -- is no longer eligible. Clear it defensively here rather than waiting
        -- for the next dw_tooltip_mouse_update() tick to do it.
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("sub-vis-off")
    end
    
    show_osd("Subtitles: " .. (nxt and "ON" or "OFF"))
    master_tick()
end

local function cmd_cycle_sec_pos()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
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
        FSM.native_sec_sub_pos = n
        show_osd("Secondary Sub Pos: " .. ((n < 50) and "TOP" or "BOTTOM"))
    end
end

local function cmd_adjust_sub_pos(delta)
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    local p = mp.get_property_number("sub-pos", 95)
    mp.set_property_number("sub-pos", math.max(0, math.min(150, p + delta)))
end

local function cmd_adjust_sec_sub_pos(delta)
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    local p = mp.get_property_number("secondary-sub-pos", 10)
    local new_pos = math.max(0, math.min(150, p + delta))
    mp.set_property_number("secondary-sub-pos", new_pos)
    FSM.native_sec_sub_pos = new_pos
end

local function cmd_cycle_sec_sid()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    FSM.native_sec_sub_vis = true
    -- [20260509180045] Synchronous Suppression: Prevent flash of native subs before next tick.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
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
    local supported = {0} -- Always include OFF (0)
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
        if internal_count > 0 then msg = msg .. " [" .. internal_count .. " built-in unsupported]" end
        show_osd(msg)
        mp.set_property("secondary-sid", "no")
        return
    end

    -- Find next sid in the supported list
    local next_sid = 0
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

    if next_sid == 0 then
        mp.set_property("secondary-sid", "no")
    else
        mp.set_property_number("secondary-sid", next_sid)
    end
    
    local label = "OFF"
    if next_sid ~= 0 then
        for _, t in ipairs(tracks) do
            if tonumber(t.id) == next_sid then
                label = t.lang and t.lang:upper() or t.title or "ON"
                if label:find("%.") then label = label:match("([^%.]+)%.") or label end
                break
            end
        end
    end
    
    local final_msg = "Secondary Sub: " .. label
    if internal_count > 0 then
        final_msg = final_msg .. " [" .. internal_count .. " built-in hidden]"
    end
    show_osd(final_msg)
    drum_osd:update()
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

local function cmd_copy_sub(mode)
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end
    
    local final_text, is_context = get_clipboard_text_smart(time_pos)

    if final_text and final_text ~= "" then
        set_clipboard(final_text, mode)
        
        local now = mp.get_time()
        if (now - (FSM.LAST_OSD_TIME or 0)) > Options.copy_osd_cooldown then
            local words, wcount = {}, 0
            for w in final_text:gmatch("%S+") do
                if wcount < Options.copy_word_limit then table.insert(words, w) end
                wcount = wcount + 1
            end
            local osd_t = table.concat(words, " ") .. (wcount > Options.copy_word_limit and "..." or "")
            show_osd("Copied " .. FSM.COPY_MODE .. ": " .. osd_t)
            FSM.LAST_OSD_TIME = now
        end
    else
        show_osd("No subtitle to copy")
    end
end


-- =========================================================================
-- SYSTEM EVENTS
-- =========================================================================

mp.observe_property("sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then Diagnostic.error("sid observer: " .. tostring(err)) end
end)
mp.observe_property("secondary-sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then Diagnostic.error("sec-sid observer: " .. tostring(err)) end
    
    -- [20260509180045] Immediate Suppression (Window 2): Enforce visibility state after track-list update.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local sec_use_osd = FSM.native_sec_sub_vis and ((FSM.DRUM == "ON") or (not Tracks.sec.is_ass and use_osd_for_srt))
    if sec_use_osd then
        mp.set_property_bool("secondary-sub-visibility", false)
    end
    drum_osd:update()
end)
mp.observe_property("track-list", "native", function()
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then Diagnostic.error("track-list observer: " .. tostring(err)) end
    if Options.font_scaling_enabled then
        local ok2, err2 = xpcall(update_font_scale, debug.traceback)
        if not ok2 then Diagnostic.error("font-scaling: " .. tostring(err2)) end
    end
end)
mp.observe_property("osd-dimensions", "native", function()
    dw_tooltip_osd:update()
    if Options.font_scaling_enabled then
        local ok, err = xpcall(update_font_scale, debug.traceback)
        if not ok then Diagnostic.error("osd-dim observer: " .. tostring(err)) end
    end
end)

mp.observe_property("pause", "bool", function(name, paused)
    if not paused then
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
    end
end)

mp.observe_property("script-opts", "string", function()
    options.read_options(Options, "kardenwort")
    validate_config()
    flush_rendering_caches()
    drum_osd:update()
    if dw_osd then dw_osd:update() end
end)

mp.register_event("shutdown", function()
    if FSM.DRUM == "ON" or FSM.DRUM_WINDOW == "DOCKED" then
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
        manage_dw_bindings(false)
    end
end)

-- =========================================================================
-- INITIALIZATION
-- =========================================================================
options.read_options(Options, "kardenwort")
validate_config()

-- Register Bindings
mp.add_key_binding(nil, "toggle-autopause", cmd_toggle_autopause)

mp.add_key_binding(nil, "toggle-karaoke-mode", cmd_toggle_karaoke)
mp.add_key_binding(nil, "smart-space", cmd_smart_space, {complex=true})
mp.add_key_binding(nil, "toggle-drum-mode", cmd_toggle_drum)
mp.add_key_binding(nil, "toggle-sub-visibility", cmd_toggle_sub_vis)
mp.add_key_binding(nil, "cycle-secondary-pos", cmd_cycle_sec_pos)
mp.add_key_binding(nil, "cycle-sec-sid", cmd_cycle_sec_sid)
mp.add_key_binding(nil, "toggle-osc-visibility", cmd_toggle_osc)
mp.add_key_binding(nil, "copy-subtitle", function() cmd_copy_sub("none") end)
mp.add_key_binding(nil, "copy-subtitle-popup", function() cmd_copy_sub("side") end)
mp.add_key_binding(nil, "copy-subtitle-main", function() cmd_copy_sub("main") end)

-- [v1.58.40] Global Ctrl+Alt+C binding for main GoldenDict window
local function register_global_copy_keys()
    local function bind(opt, name, fn)
        if not opt or opt == "" then return end
        local i = 1
        local expanded_keys = expand_ru_keys(opt, name)
        for _, key in ipairs(expanded_keys) do
            local wrapped_fn = function(t)

                return fn(t)
            end
            mp.add_key_binding(key, name .. "-" .. i, wrapped_fn)
            i = i + 1
        end
    end
    bind(Options.key_copy_popup, "kardenwort-global-copy-side", function() cmd_copy_sub("side") end)
    bind(Options.key_copy_main, "kardenwort-global-copy-main", function() cmd_copy_sub("main") end)
end
register_global_copy_keys()
mp.add_key_binding(nil, "cycle-copy-mode", cmd_cycle_copy_mode)
mp.add_key_binding(nil, "toggle-copy-context", cmd_toggle_copy_ctx)
mp.add_key_binding(nil, "toggle-drum-window", cmd_toggle_drum_window)
mp.add_key_binding(nil, "toggle-drum-search", cmd_toggle_search)
mp.add_key_binding(nil, "toggle-book-mode", toggle_book_mode)
mp.add_key_binding(nil, "replay-subtitle", cmd_replay_sub)
mp.add_key_binding(nil, "seek_prev", function(t) cmd_seek_with_repeat(-1, t) end, {complex = true})
mp.add_key_binding(nil, "seek_next", function(t) cmd_seek_with_repeat(1, t) end, {complex = true})

mp.add_key_binding(nil, "seek_time_forward", function() cmd_seek_time(1) end, {repeatable = true})
mp.add_key_binding(nil, "seek_time_backward", function() cmd_seek_time(-1) end, {repeatable = true})
mp.add_key_binding(nil, "toggle-anki-global", cmd_toggle_anki_global)
mp.add_key_binding(nil, "toggle-record-file", cmd_open_record_file)

local function register_global_position_keys()
    local function bind(opt, name, fn)
        if not opt or opt == "" then return end
        local i = 1
        local expanded_keys = expand_ru_keys(opt, name)
        for _, key in ipairs(expanded_keys) do
            local wrapped_fn = function(t)

                return fn(t)
            end
            mp.add_forced_key_binding(key, name .. "-" .. i, wrapped_fn)
            i = i + 1
        end
    end
    bind(Options.key_sub_pos_up, "kardenwort-sub-pos-up", function() cmd_adjust_sub_pos(-1) end)
    bind(Options.key_sub_pos_down, "kardenwort-sub-pos-down", function() cmd_adjust_sub_pos(1) end)
    bind(Options.key_sec_sub_pos_up, "kardenwort-sec-sub-pos-up", function() cmd_adjust_sec_sub_pos(-1) end)
    bind(Options.key_sec_sub_pos_down, "kardenwort-sec-sub-pos-down", function() cmd_adjust_sec_sub_pos(1) end)
end
register_global_position_keys()

local function register_global_playback_keys()
    local function bind(opt, name, fn)
        if not opt or opt == "" then return end
        local i = 1
        local expanded_keys = expand_ru_keys(opt, name)
        for _, key in ipairs(expanded_keys) do
            mp.add_key_binding(key, name .. "-" .. i, fn)
            i = i + 1
        end
    end
    -- Note: replay-subtitle is handled globally via the named binding in input.conf.
    -- No direct key binding needed here to avoid double-fire collision.
end
register_global_playback_keys()

if Options.anki_sync_period > 0 then
    mp.add_periodic_timer(Options.anki_sync_period, function()
        local ok, err = xpcall(function()
            find_source_url()
            load_anki_tsv(false, true)
            drum_osd:update()
            if dw_osd then dw_osd:update() end
        end, debug.traceback)
        if not ok then Diagnostic.error("periodic sync: " .. tostring(err)) end
    end)
end
Diagnostic.info("SCRIPT LOADED SUCCESSFULLY")


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

-- [v1.58.51] Global Immersion Mode Toggle (Shift+o / O Щ)
-- Parameterized to allow user overrides via mpv.conf
for k in string.gmatch(Options.key_cycle_immersion_mode, "%S+") do
    mp.add_forced_key_binding(k, "kardenwort-cycle-immersion-" .. k, cmd_cycle_immersion_mode)
end

-- =========================================================================
-- STATE PROBE (test instrumentation)
-- Dormant in production. Activated by IPC `script-message-to kardenwort ...`.
-- =========================================================================
local kardenwortProbe = {}

function kardenwortProbe._snapshot()
    local safe_search_results = {}
    for _, r in ipairs(FSM.SEARCH_RESULTS or {}) do
        table.insert(safe_search_results, {
            idx = r.idx,
            text = r.text
        })
    end

    local tracks_summary = {
        pri = { 
            id = Tracks.pri.id, 
            is_ass = Tracks.pri.is_ass, 
            path = Tracks.pri.path,
            count = #(Tracks.pri.subs or {})
        },
        sec = { 
            id = Tracks.sec.id, 
            is_ass = Tracks.sec.is_ass, 
            path = Tracks.sec.path,
            count = #(Tracks.sec.subs or {})
        }
    }
    
    return {
        options            = Options,
        autopause          = FSM.AUTOPAUSE,
        drum_mode          = FSM.DRUM,
        drum_window        = FSM.DRUM_WINDOW,
        active_sub_index     = FSM.ACTIVE_IDX,
        sec_active_sub_index = FSM.SEC_ACTIVE_IDX,
        playback_state     = FSM.MEDIA_STATE,
        pri_sub_count      = #(Tracks.pri.subs or {}),
        sec_sub_count      = #(Tracks.sec.subs or {}),
        dw_cursor          = { line = FSM.DW_CURSOR_LINE, word = FSM.DW_CURSOR_WORD },
        dw_active_line     = FSM.DW_ACTIVE_LINE,
        dw_anchor          = { line = FSM.DW_ANCHOR_LINE, word = FSM.DW_ANCHOR_WORD },
        dw_selection_count = #(FSM.DW_CTRL_PENDING_LIST or {}),
        dw_view_center     = FSM.DW_VIEW_CENTER,
        dw_follow_player   = FSM.DW_FOLLOW_PLAYER,
        immersion_mode     = FSM.IMMERSION_MODE,
        copy_mode          = FSM.COPY_MODE,
        loop_mode          = FSM.LOOP_MODE,
        book_mode          = FSM.BOOK_MODE,
        native_sub_vis     = FSM.native_sub_vis,
        native_sec_sub_vis = FSM.native_sec_sub_vis,
        native_sec_sub_pos = FSM.native_sec_sub_pos,
        replay_remaining      = FSM.REPLAY_REMAINING or 0,
        rewind_transit_active = FSM.TIMESEEK_INHIBIT_UNTIL ~= nil,
        rewind_transit_until  = FSM.TIMESEEK_INHIBIT_UNTIL or 0,
        rewind_transit_cross_card = FSM.REWIND_TRANSIT_CROSS_CARD == true,
        last_paused_sub_end   = FSM.last_paused_sub_end,
        karaoke_mode          = FSM.KARAOKE,
        search_mode           = FSM.SEARCH_MODE,
        search_query       = FSM.SEARCH_QUERY,
        search_results     = safe_search_results,
        dw_tooltip_mode    = FSM.DW_TOOLTIP_MODE,
        tracks             = tracks_summary,
        fsm_state          = FSM.MEDIA_STATE, -- Alias for easier access in some tests
        test_data          = FSM.TEST_DATA or {},
        layout_version     = FSM.LAYOUT_VERSION or 0,
        tooltip_forced     = FSM.DW_TOOLTIP_FORCE,
        tooltip_cache_size = #(FSM.DW_TOOLTIP_SEC_SUBS or {}),
        dw_sticky_x        = FSM.DW_CURSOR_X,
        anki_db_mtime      = FSM.ANKI_DB_MTIME or 0,
        anki_db_size       = FSM.ANKI_DB_SIZE or 0,
        platform           = package.config:sub(1,1) == "\\" and "windows" or "unix"
    }
end

local _probe_seq = 0

mp.register_script_message("state-query", function()
    _probe_seq = _probe_seq + 1
    local snap = kardenwortProbe._snapshot()
    snap._seq = _probe_seq
    mp.set_property("user-data/kardenwort/state", utils.format_json(snap))
end)

mp.register_script_message("render-query", function(overlay_name)
    local map = {
        drum    = drum_osd,
        dw      = dw_osd,
        tooltip = dw_tooltip_osd,
        search  = search_osd,
        seek    = seek_osd,
    }
    local osd = map[overlay_name]
    local data = (osd and osd.data) or ""
    _probe_seq = _probe_seq + 1
    mp.set_property("user-data/kardenwort/render", _probe_seq .. "|" .. data)
end)

-- Test Instrumentation
mp.register_script_message("immersion-mode-set", function(mode)
    if mode == "MOVIE" or mode == "PHRASE" then
        FSM.IMMERSION_MODE = mode
        master_tick()
    end
end)

mp.register_script_message("autopause-set", function(state)
    if state == "ON" or state == "OFF" then
        FSM.AUTOPAUSE = state
    end
end)

mp.register_script_message("adjust-sec-sub-pos", function(val)
    cmd_adjust_sec_sub_pos(tonumber(val))
end)

mp.register_script_message("native-sec-sub-pos-set", function(val)
    local n = tonumber(val)
    if n then
        FSM.native_sec_sub_pos = n
        mp.set_property_number("secondary-sub-pos", n)
    end
end)

mp.register_script_message("toggle-sub-vis", function()
    cmd_toggle_sub_vis()
end)

mp.register_script_message("drum-window-toggle", function()
    cmd_toggle_drum_window()
end)

mp.register_script_message("test-bind-seek", function()
    mp.add_forced_key_binding("KP0", "kardenwort-seek_time_forward", function() cmd_seek_time(1) end, {repeatable = true})
    mp.add_forced_key_binding("KP1", "kardenwort-seek_time_backward", function() cmd_seek_time(-1) end, {repeatable = true})
end)

mp.register_script_message("test-dw-word-move", function(dir, shift)
    Diagnostic.info("RECEIVED kardenwort-test-dw-word-move: " .. tostring(dir) .. " " .. tostring(shift))
    cmd_dw_word_move(tonumber(dir), shift == "yes" or shift == "true")
end)

mp.register_script_message("test-ctrl-toggle-word", function(line_str, word_str)
    local line, word = tonumber(line_str), tonumber(word_str)
    if line and word then ctrl_toggle_word(line, word, false) end
end)

mp.register_script_message("test-dw-esc", function()
    cmd_dw_esc()
end)

mp.register_script_message("test-dw-tooltip-toggle", function()
    cmd_dw_tooltip_toggle()
end)

mp.register_script_message("test-dw-line-move", function(dir_str, shift)
    local dir = tonumber(dir_str)
    if dir then cmd_dw_line_move(dir, shift == "yes" or shift == "true") end
end)

mp.register_script_message("test-dw-scroll", function(dir_str)
    local dir = tonumber(dir_str)
    if dir then cmd_dw_scroll(dir) end
end)

mp.register_script_message("test-replay", function()
    cmd_replay_sub()
end)

mp.register_script_message("test-seek-time", function(dir_str)
    local dir = tonumber(dir_str)
    if dir then cmd_seek_time(dir) end
end)

mp.register_script_message("test-set-cursor", function(line_str, word_str)
    local line, word = tonumber(line_str), tonumber(word_str)
    if line and word then
        FSM.DW_CURSOR_LINE = line
        FSM.DW_CURSOR_WORD = word
        FSM.DW_CURSOR_X = nil
    end
end)

mp.register_script_message("test-set-follow-player", function(state)
    FSM.DW_FOLLOW_PLAYER = (state == "ON" or state == "true")
end)

mp.register_script_message("test-seek-delta", function(dir_str)
    local dir = tonumber(dir_str)
    if dir then cmd_dw_seek_delta(dir) end
end)

mp.register_script_message("seek_next", function() cmd_seek_with_repeat(1, nil) end)
mp.register_script_message("seek_prev", function() cmd_seek_with_repeat(-1, nil) end)
mp.register_script_message("test-cycle-sec-sid", function()
    cmd_cycle_sec_sid()
end)

mp.register_script_message("sub-visibility-set", function(state)
    local val = (state == "ON")
    FSM.native_sub_vis = val
    FSM.native_sec_sub_vis = val
    master_tick()
end)

mp.register_script_message("drum-mode-set", function(state)
    if state == "ON" or state == "OFF" then
        FSM.DRUM = state
        master_tick()
    end
end)

mp.register_script_message("test-dw-export-pink", function()
    Diagnostic.info("RECEIVED kardenwort-test-dw-export-pink")
    ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
end)

mp.register_script_message("test-dw-export-yellow", function()
    cmd_dw_anki_export_selection()
end)

mp.register_script_message("test-prepare-export", function(type, p1_l, p1_w, p2_l, p2_w)
    local params
    if type == "RANGE" then
        params = { type = "RANGE", p1_l = tonumber(p1_l), p1_w = tonumber(p1_w), p2_l = tonumber(p2_l), p2_w = tonumber(p2_w) }
    elseif type == "SET" then
        params = { type = "SET", members = FSM.DW_CTRL_PENDING_LIST }
    else
        params = { type = "POINT", line = tonumber(p1_l), word = tonumber(p1_w) }
    end
    local term = prepare_export_text(params, { clean = true, restore_sentence = true })
    mp.set_property("user-data/kardenwort/last_export", term)
end)

mp.register_script_message("test-dw-copy", function()
    cmd_dw_copy()
end)

mp.register_script_message("test-search-input", function(char)
    if FSM.SEARCH_MODE then
        -- This is a simplification of the actual char handler
        local q_table = utf8_to_table(FSM.SEARCH_QUERY)
        table.insert(q_table, FSM.SEARCH_CURSOR + 1, char)
        FSM.SEARCH_QUERY = table.concat(q_table)
        FSM.SEARCH_CURSOR = FSM.SEARCH_CURSOR + 1
        -- trigger update
        update_search_results()
        render_search()
    end
end)

mp.register_script_message("test-get-tokens", function(text)
    local tokens = build_word_list_internal(text, true)
    local snap = {}
    for i, t in ipairs(tokens) do
        table.insert(snap, { text = t.text, logical_idx = t.logical_idx, is_word = t.is_word })
    end
    FSM.TEST_DATA = FSM.TEST_DATA or {}
    FSM.TEST_DATA.test_tokens = snap
end)

mp.register_script_message("test-set-option", function(name, val)
    if val == "yes" or val == "true" then val = true
    elseif val == "no" or val == "false" then val = false
    elseif tonumber(val) then val = tonumber(val) end
    Options[name] = val
    if name == "book_mode" then FSM.BOOK_MODE = val end
    flush_rendering_caches()
end)

mp.register_script_message("test-dw-toggle", function()
    cmd_toggle_drum_window()
end)

mp.register_script_message("test-dw-tooltip-pin", function(arg1)
    local tbl = { event = "down" }
    if arg1 and arg1:sub(1,1) == "{" then
        local ok, parsed = pcall(utils.parse_json, arg1)
        if ok and parsed then tbl = parsed end
    end
    cmd_dw_tooltip_pin(tbl)
end)

mp.register_script_message("test-dw-tooltip-pin-at", function(x_str, y_str, arg3)
    local x, y = tonumber(x_str), tonumber(y_str)
    if not x or not y then return end
    local tbl = { event = "down" }
    if arg3 and arg3:sub(1,1) == "{" then
        local ok, parsed = pcall(utils.parse_json, arg3)
        if ok and parsed then tbl = parsed end
    end
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then return end
    if tbl.event == "down" then
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_HOLDING = true
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end
        local line_idx
        if dw_mode then
            line_idx = select(1, dw_hit_test(x, y))
        else
            line_idx = select(1, kardenwort_hit_test_all(x, y))
        end
        if line_idx then
            FSM.DW_TOOLTIP_LOCKED_LINE = -1
            FSM.DW_TOOLTIP_LINE = line_idx
            local py = get_tooltip_line_y(line_idx, y)
            if py then py = math.floor(py + 0.5) end
            local ass = draw_dw_tooltip(subs, line_idx, py)
            if ass ~= dw_tooltip_osd.data then
                dw_tooltip_osd.data = ass
                dw_tooltip_osd:update()
            end
        end
    elseif tbl.event == "up" then
        FSM.DW_TOOLTIP_HOLDING = false
    end
end)

mp.register_script_message("test-dw-key", function(key)
    local shift = key:find("Shift%+") ~= nil
    local ctrl = key:find("Ctrl%+") ~= nil
    local base = key:gsub("Shift%+", ""):gsub("Ctrl%+", "")
    
    if base == "DOWN" then cmd_dw_line_move(1, shift)
    elseif base == "UP" then cmd_dw_line_move(-1, shift)
    elseif base == "LEFT" then cmd_dw_word_move(-1, shift, ctrl)
    elseif base == "RIGHT" then cmd_dw_word_move(1, shift, ctrl)
    elseif key == "e" then 
        FSM.DW_TOOLTIP_FORCE = not FSM.DW_TOOLTIP_FORCE
        if FSM.DW_TOOLTIP_FORCE then FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR" end
    elseif key == "r" then
        cmd_dw_pair_word()
    elseif key == "o" then
        cmd_dw_open_record()
    end
end)

mp.register_script_message("test-dw-double-click", function(line_str)
    local ok, err = xpcall(function()
        local line = tonumber(line_str)
        if line and Tracks and Tracks.pri and Tracks.pri.subs then
            local sub = Tracks.pri.subs[line]
            if sub then
                mp.set_property_number("time-pos", sub.start_time)
                if FSM.BOOK_MODE then
                    FSM.DW_FOLLOW_PLAYER = false
                else
                    FSM.DW_FOLLOW_PLAYER = true
                    FSM.DW_CURSOR_LINE = line
                    FSM.DW_CURSOR_WORD = -1
                    FSM.DW_VIEW_CENTER = line
                end
                FSM.ACTIVE_IDX = line
                master_tick()
                flush_rendering_caches()
            end
        end
    end, debug.traceback)
    if not ok then Diagnostic.error("kardenwort-test-dw-double-click error: " .. tostring(err)) end
end)

mp.register_script_message("test-truncate", function(text)
    local truncated = text
    if #text > 120 then
        truncated = text:sub(1, 120) .. "..."
    end
    FSM.TEST_DATA = FSM.TEST_DATA or {}
    FSM.TEST_DATA.test_truncated_str = truncated
end)

mp.register_script_message("test-validate-term", function(term)
    local clean = term:gsub("{.-}", ""):match("^%s*(.-)%s*$")
    local valid = (clean and #clean > 0)
    FSM.TEST_DATA = FSM.TEST_DATA or {}
    FSM.TEST_DATA.test_term_valid = valid
end)

mp.register_script_message("test-search-mode-set", function(state)
    FSM.SEARCH_MODE = (state == "ON" or state == "true")
    if FSM.SEARCH_MODE then
        FSM.SEARCH_QUERY = ""
        FSM.SEARCH_CURSOR = 0
        render_search()
    end
end)

mp.register_script_message("test-hit-test", function(x_str, y_str)
    local x, y = tonumber(x_str), tonumber(y_str)
    local l, w, p = drum_osd_hit_test(x, y)
    FSM.TEST_DATA = FSM.TEST_DATA or {}
    FSM.TEST_DATA.hit_test_res = { line = l, word = w, is_pri = p }
end)

mp.register_script_message("test-query-tooltip-state", function()
    local res = {
        data = dw_tooltip_osd.data,
        line = FSM.DW_TOOLTIP_LINE,
        holding = FSM.DW_TOOLTIP_HOLDING,
        force = FSM.DW_TOOLTIP_FORCE
    }
    mp.set_property("user-data/test-tooltip-state", utils.format_json(res))
end)

mp.register_script_message("test-query-hit-zones", function()
    FSM.TEST_DATA = FSM.TEST_DATA or {}
    FSM.TEST_DATA.drum_hit_zones = FSM.DRUM_HIT_ZONES
end)

mp.register_script_message("test-fuzzy-match", function(query, target)
    local q = query:lower():gsub("%s+", "")
    local t = target:lower()
    local q_idx = 1
    for i = 1, #t do
        if t:sub(i, i) == q:sub(q_idx, q_idx) then
            q_idx = q_idx + 1
            if q_idx > #q then break end
        end
    end
    FSM.TEST_DATA = FSM.TEST_DATA or {}
    FSM.TEST_DATA.test_fuzzy_match_result = (q_idx > #q)
end)

mp.register_script_message("test-expand-ru-keys", function(key_str)
    local results = expand_ru_keys(key_str, "test-expand")
    mp.set_property("user-data/kardenwort/last_export", utils.format_json(results))
end)

-- Test instrumentation for missed functional coverage (ZID: 20260512130623)
mp.register_script_message("test-set-search-query", function(query)
    -- Deterministic acceptance-test hook:
    -- ensure primary subtitle memory is available even if Search UI was not toggled.
    if Tracks.pri.path and (not Tracks.pri.subs or #Tracks.pri.subs == 0) then
        Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
    end
    FSM.SEARCH_QUERY = query or ""
    FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
    FSM.SEARCH_ANCHOR = -1
    update_search_results()
    render_search()
end)

mp.register_script_message("test-search-delete-word", function()
    -- Deterministic acceptance-test hook (independent from keybinding scope).
    local before = FSM.SEARCH_QUERY or ""
    if before == "" then return end
    local trimmed = before:gsub("%s*%S+$", "")
    if trimmed ~= "" and not trimmed:match("%s$") then
        trimmed = trimmed .. " "
    end
    FSM.SEARCH_QUERY = trimmed
    FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
    FSM.SEARCH_ANCHOR = -1
end)

mp.register_script_message("test-export-selection", function()
    sync_ctrl_pending_list()
    local members = FSM.DW_CTRL_PENDING_LIST or {}
    if #members > 0 then
        local first = members[1]
        ctrl_commit_set(first.line, first.word)
        return
    end
    dw_anki_export_selection()
end)

