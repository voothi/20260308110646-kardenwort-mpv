local mp = require 'mp'
local utils = require 'mp.utils'
local options = require 'mp.options'

print("[LLS] SCRIPT INITIALIZING: " .. (mp.get_script_directory and mp.get_script_directory() or "<unknown dir>"))

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
    drum_font_name = "Inter",
    drum_font_bold = false,
    drum_context_lines = 2,
    drum_context_opacity = "30",
    drum_context_color = "FFFFFF",
    drum_context_bold = false,
    drum_context_size_mul = 1.0,
    drum_active_opacity = "00",
    drum_active_color = "FFFFFF",
    drum_active_bold = false,
    drum_active_size_mul = 1.0,
    drum_spacing_gap = -0.1,
    drum_stack_multiplier = 1.15,
    drum_bg_opacity = "60",        -- Frame transparency (ASS alpha 00-FF)
    drum_border_size = 1.5,
    drum_shadow_offset = 1.0,
    drum_track_gap = 5.0,         -- Extra spacing between dual tracks (%)

    -- SRT Style (Regular Mode)
    srt_font_size = 55,
    srt_font_name = "Inter",
    srt_font_bold = true,

    -- Copy Mode
    copy_default_mode = "A",
    copy_filter_russian = true,
    copy_context_lines = 2,
    copy_word_limit = 3,

    -- Toggle Positions
    -- [NOTE] sec_pos_bottom should be ~5% LESS than sub-pos in mpv.conf 
    -- to prevent primary and secondary subtitles from overlapping at the bottom.
    sec_pos_top = 10,
    sec_pos_bottom = 80,

    -- System
    tick_rate = 0.05,
    osd_duration = 1.0,

    -- Drum Window
    dw_font_size = 34,
    dw_lines_visible = 15,        -- how many lines visible in the window
    dw_bg_color = "000000",       -- black in BGR hex for ASS
    dw_bg_opacity = "60",         -- background opacity (00-FF, 00 is opaque)
    dw_text_color = "CCCCCC",     -- light text
    dw_text_opacity = "00",       -- text alpha
    dw_active_color = "FFFFFF",   -- white active text in BGR
    dw_highlight_color = "00CCFF",-- Gold highlight in BGR
    dw_ctrl_select_color = "FF88FF",-- Neon pink for split-word select (pairing with purple)
    dw_font_name = "Consolas",    -- monospace font for perfect hit-testing
    dw_font_bold = false,
    dw_char_width = 0.5,          -- char width multiplier (0.5 is exact for Consolas)
    dw_vline_h_mul = 0.87,        -- visual line height = dw_font_size * this (calibrated for font 34, use 0.9 for font 30)
    dw_sub_gap_mul = 0.6,         -- gap between subtitles = dw_font_size * this (calibrated for font 34, use 0.6 for font 30)
    dw_border_size = 1.5,
    dw_shadow_offset = 1.0,
    dw_original_spacing = true,

    -- Search HUD Styling
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
    tooltip_context_lines = 1,
    tooltip_bg_opacity = "60",
    tooltip_bg_color = "222222",
    tooltip_text_color = "CCCCCC",
    tooltip_font_name = "Inter",
    tooltip_text_opacity = "00",
    tooltip_font_bold = false,
    tooltip_border_size = 1.5,
    tooltip_shadow_offset = 1.0,

    -- Navigation Repeat
    seek_hold_delay = 0.5,
    seek_hold_rate = 10,

    -- Anki Highlighter
    dw_key_add = "MBTN_MID Ctrl+MBTN_MID r к",
    dw_key_pair = "t е Ctrl+MBTN_LEFT",
    dw_key_select = "MBTN_LEFT",
    dw_key_tooltip_pin = "MBTN_RIGHT",
    dw_key_tooltip_hover = "n т",
    dw_key_tooltip_toggle = "e у",
    anki_context_max_words = 40,
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
    book_mode = false,

    -- Record File
    record_editor = "C:\\Program Files\\Microsoft VS Code\\Code.exe",
    
    -- Colors
    dw_split_select_color = "FF88B0",
    book_mode = false,
    sentence_word_threshold = 3
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
    DW_ANCHOR_LINE = -1,       -- Shift-anchor line index
    DW_ANCHOR_WORD = -1,       -- Shift-anchor word index
    DW_VIEW_CENTER = -1,       -- Viewport center line index
    DW_FOLLOW_PLAYER = true,   -- Follow active playback line?
    DW_KEY_OVERRIDE = false,   -- Are we overriding arrow keys?
    DW_MOUSE_DRAGGING = false, -- True while LMB is held and dragging
    DW_CTRL_HELD = false,      -- True while Ctrl key is held in DW
    DW_CTRL_PENDING_SET = {},  -- Non-contiguous word selection {{line, word}, ...}
    DW_MOUSE_SCROLL_TIMER = nil, -- Timer for auto-scroll while dragging at edges

    -- Global Search State
    SEARCH_MODE = false,
    SEARCH_QUERY = "",
    SEARCH_RESULTS = {},
    SEARCH_SEL_IDX = 1,
    SEARCH_CURSOR = 0,
    SEARCH_ANCHOR = -1,

    -- Transient UI State
    saved_osd_border_style = nil,

    -- Tooltip State
    DW_TOOLTIP_LINE = -1,
    DW_TOOLTIP_MODE = "CLICK",
    DW_TOOLTIP_HOLDING = false,
    DW_TOOLTIP_LOCKED_LINE = -1,
    DW_TOOLTIP_FORCE = false,   -- Manual keyboard toggle state
    DW_LINE_Y_MAP = {},         -- Map of {sub_idx = osd_y} for active tooltip tracking
    DW_ACTIVE_LINE = -1,        -- Currently playing subtitle index
    DW_TOOLTIP_TARGET_MODE = "ACTIVE", -- Target switching for forced tooltip ("ACTIVE" or "CURSOR")
    DW_MOUSE_LOCK_UNTIL = 0,         -- Timestamp to ignore mouse events (shielding)

    -- Repeat Timer
    SEEK_REPEAT_TIMER = nil,

    -- Anki Highlighter State
    ANKI_HIGHLIGHTS = {},
    ANKI_DB_PATH = nil
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

-- =========================================================================
-- DRUM WINDOW CTRL-SELECT ACCUMULATOR
-- =========================================================================


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
local LAST_PATH_FOR_URL = nil

local function find_source_url()
    local path = mp.get_property("path")
    if not path or path == "" then return "" end
    
    -- Cache validation: if we have a file path, verify it still exists
    if path == LAST_PATH_FOR_URL and SOURCE_URL_FILE_PATH then
        local f = io.open(SOURCE_URL_FILE_PATH, "r")
        if f then
            f:close()
        else
            -- File was deleted or renamed, invalidate cache
            SOURCE_URL_CACHE = nil
            SOURCE_URL_FILE_PATH = nil
        end
    end

    -- Cache check: only re-scan if the media path changed OR if we haven't found a URL yet
    if path == LAST_PATH_FOR_URL and SOURCE_URL_CACHE ~= nil and SOURCE_URL_CACHE ~= "" then 
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

local function clean_text_srt(line)
    line = line:gsub("^\xEF\xBB\xBF", "")
    return line:gsub("\r", ""):gsub("<[^>]+>", "")
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

local function build_word_list_internal(text, keep_spaces)
    local tokens = {}
    if not text then return tokens end
    
    local chars = utf8_to_table(text)
    local i = 1
    local n = #chars
    local curr_logical_idx = 1
    local curr_visual_idx = 1
    
    while i <= n do
        local c = chars[i]
        local token = { text = "", is_word = false, logical_idx = nil, visual_idx = curr_visual_idx }
        
        -- 1. Handle ASS Tags (Atomize)
        if c == "{" then
            local start = i
            while i <= n and chars[i] ~= "}" do i = i + 1 end
            token.text = table.concat(chars, "", start, i)
            i = i + 1
            
        -- 2. Handle Metadata Brackets (Atomize)
        elseif c == "[" then
            local start = i
            while i <= n and chars[i] ~= "]" do i = i + 1 end
            token.text = table.concat(chars, "", start, i)
            i = i + 1
            
        -- 3. Handle Whitespace
        elseif c:match("^%s$") then
            local start = i
            while i <= n and chars[i]:match("^%s$") do i = i + 1 end
            if keep_spaces then
                token.text = table.concat(chars, "", start, i - 1)
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
            
        -- 5. Handle Punctuation/Misc (Atomic Separator)
        else
            token.text = c
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

local function calculate_highlight_stack(subs, sub_idx, token_idx, time_pos)
    if not next(FSM.ANKI_HIGHLIGHTS) or not subs or not subs[sub_idx] then return 0, 0, false end
    
    local tokens = get_sub_tokens(subs[sub_idx])
    if not tokens then return 0, 0, false end
    
    local target_token = tokens[token_idx]
    if not target_token or not target_token.is_word then return 0, 0, false end
    
    local target_l_idx = target_token.logical_idx
    local target_word_text = target_token.text
    local target_lower_full = utf8_to_lower(target_word_text:gsub("[%p%s]", ""))
    if target_lower_full == "" then return 0, 0, false end

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
                if t.logical_idx == target_logical_idx then
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
    local has_phrase = false
    local matched_terms = {}
    for _, data in ipairs(FSM.ANKI_HIGHLIGHTS) do
        local term_key = data.term
        if not matched_terms[term_key] then
            local match_found = false
            local term_is_split = false
            
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
                data.__ctx_lower = utf8_to_lower(data.context:gsub("{[^}]+}", ""))

                -- Parse string indices (if not already parsed during load)
                if data.index and not data.__pivots then
                    data.__pivots = {}
                    for part in (tostring(data.index) .. ","):gmatch("([^,]*),") do
                        local l_off, p_idx, t_pos = part:match("^([%-+]?%d+):(%d+):(%d+)$")
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
            if #term_clean > 10 then window = window + (#term_clean * 0.5) end

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

                        -- Phase 2: Context Match
                        local needs_strict = Options.anki_context_strict or (#term_clean == 1)
                        if sequence_match then
                            -- For large blocks with multi-pivot data, verify grounding for ALL points
                            if data.__pivots and #data.__pivots > 1 and not Options.anki_global_highlight then
                                local all_pivots_grounded = true
                                local origin_l = get_center_index(subs, data.time)
                                if origin_l == -1 then all_pivots_grounded = false
                                else
                                    for _, g in ipairs(data.__pivots) do
                                        local rel_s = g.l_off
                                        local target_s = origin_l + rel_s
                                        local target_sub = subs[target_s]
                                        if not target_sub then all_pivots_grounded = false; break end
                                        
                                        local t_tokens = get_sub_tokens(target_sub)
                                        local found = false
                                        for _, t in ipairs(t_tokens) do
                                            if t.is_word and t.logical_idx == g.p_idx then
                                                found = true; break
                                            end
                                        end
                                        if not found then all_pivots_grounded = false; break end
                                    end
                                end
                                
                                if all_pivots_grounded then
                                    any_sequence = true
                                    break
                                end
                            else
                                -- Basic grounding (one pivot or global mode)
                                local context_satisfied = (not needs_strict)
                                if not context_satisfied then
                                    -- Check if current word (term_offset) is grounded
                                    if data.__pivots and #data.__pivots > 0 and not Options.anki_global_highlight then
                                        local g = data.__pivots[1]
                                        local origin_l = get_center_index(subs, data.time)
                                        if sub_idx == origin_l + g.l_off and target_l_idx == g.p_idx then
                                            context_satisfied = true
                                        end
                                    end
                                    
                                    if not context_satisfied and (Options.anki_global_highlight or not (data.__pivots and #data.__pivots > 0)) then
                                        -- Fuzzy context check
                                        local match_count = 0
                                        local scan_pad = Options.anki_neighbor_window or 5
                                        for s_off = -scan_pad, scan_pad do
                                            local scan_sub = subs[sub_idx + s_off]
                                            if scan_sub then
                                                local s_text = utf8_to_lower(scan_sub.text:gsub("{[^}]+}", ""))
                                                if data.__ctx_lower:find(s_text, 1, true) then match_count = match_count + 1 end
                                            end
                                        end
                                        context_satisfied = (match_count >= 1)
                                    end
                                end

                                if context_satisfied then
                                    any_sequence = true
                                    break
                                end
                            end
                        end
                    end

                    if any_sequence then
                        match_found = true
                        if #term_clean > 1 then has_phrase = true end
                    elseif #term_clean > 1 then
                        local origin_sub_idx = get_center_index(subs, data.time)
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
                                    if gap < Options.anki_split_gap_limit then
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
                                                    if not (m and m.s_i == origin_sub_idx + g.l_off and m.l_i == g.p_idx) then
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
                                
                                -- Fallback to unanchored match if ground-truth coordinate check failed
                                if not best_tuple and best_unanchored_tuple then
                                    best_tuple = best_unanchored_tuple
                                end
                                
                                if best_tuple then
                                    valid_set = {}
                                    for _, c_idx in ipairs(best_tuple) do
                                        local cw_obj = ctx_list[c_idx]
                                        valid_set[cw_obj.s_i .. "-" .. cw_obj.t_i] = true
                                    end
                                end
                            end
                            subs[sub_idx].__split_valid_indices[term_key] = valid_set
                        end
                        
                        if valid_set and valid_set[sub_idx .. "-" .. token_idx] then
                            match_found = true
                            term_is_split = true
                        end
                    end
                end
            end

            if match_found then
                if term_is_split then purple_stack = purple_stack + 1
                else orange_stack = orange_stack + 1 end
                matched_terms[term_key] = true
            end
        end
    end
    return orange_stack, purple_stack, has_phrase
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

local function extract_anki_context(full_line, selected_term, max_words_override, pivot_pos)
    if not full_line or full_line == "" then return "" end
    
    -- 1. Try to find the occurrence closest to the pivot position (or center if not provided).
    -- This handles ambiguous common words (e.g. "die") when multiple context lines are present.
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
        search_from = e + 1
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
        local min_s, max_e = nil, nil
        
        for word in term_lower:gmatch("%S+") do
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
                s_from = we + 1
            end
            
            if best_ws then
                min_s = (not min_s) and best_ws or math.min(min_s, best_ws)
                max_e = (not max_e) and best_we or math.max(max_e, best_we)
            end
        end
        
        if min_s then
            start_pos, end_pos = min_s, max_e
        end
    end
    
    local sentence = full_line
    if start_pos then
        local is_sentence_start = false
        -- Search backwards for punctuation
        local pre = full_line:sub(1, start_pos - 1)
        local sent_start = 1
        -- Look for space followed by . ! ? in reversed string (meaning . ! ? followed by space in original)
        local b_idx = pre:reverse():find("%s+[.!?]")
        if b_idx then
            sent_start = start_pos - b_idx + 1
            is_sentence_start = true
        else
            -- No preceding punctuation found, meaning it starts at the beginning of the text block.
            -- This acts as a sentence boundary.
            sent_start = 1
            is_sentence_start = true
        end
        
        -- Search forwards for punctuation starting safely AFTER the term
        -- to ensure we don't cut off multi-sentence selections if they end near punctuation.
        local post = full_line:sub(end_pos + 1)
        local sent_end = #full_line
        local f_idx = post:find("[.!?]")
        if f_idx then
            sent_end = end_pos + f_idx
        end
        
        sentence = full_line:sub(sent_start, sent_end):match("^[%s.!?]*(.-)%s*$")
        
        if is_sentence_start and sentence and sentence ~= "" and starts_with_uppercase(sentence) then
            if not sentence:match("[.!?]$") then
                sentence = sentence .. "."
            end
        end
    end

    -- 2. Check word count of the extracted sentence.
    -- We use a dynamic limit to avoid overly aggressive truncation for long selections.
    local words = build_word_list(sentence)
    local limit = max_words_override or Options.anki_context_max_words
    if #words <= limit then return sentence end
    
    -- 3. If the sentence is still too long, fallback to word-based truncation around the term
    local selected_words = build_word_list(selected_term)
    if #selected_words == 0 then return sentence:sub(1, 100) .. "..." end
    
    local target_idx = -1
    for i = 1, #words - #selected_words + 1 do
        local match = true
        for j = 1, #selected_words do
            if words[i + j - 1] ~= selected_words[j] then match = false break end
        end
        if match then target_idx = i break end
    end
    
    if target_idx == -1 then return sentence:sub(1, 100) .. "..." end
    
    local last_idx = target_idx + #selected_words - 1
    local half_max = math.floor(limit / 2)
    local context_start = math.max(1, target_idx - half_max)
    local context_end = math.min(#words, last_idx + half_max)
    
    local context_words = {}
    for i = context_start, context_end do table.insert(context_words, words[i]) end
    
    return compose_term_smart(context_words):match("^%s*(.-)%s*$")
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
                            if raw_text ~= "" and not has_cyrillic(raw_text) then
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
        for raw_line in f:lines() do
            local line = clean_text_srt(raw_line)
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
    
    if FSM.ANKI_DB_PATH ~= tsv_path then
        FSM.ANKI_DB_PATH = tsv_path
        FSM.ANKI_HIGHLIGHTS = {}
    elseif not force then
        if next(FSM.ANKI_HIGHLIGHTS) ~= nil then return end
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
                        for part in (tostring(idx_val) .. ","):gmatch("([^,]*),") do
                            local l_off, p_idx, t_pos = part:match("^([%-+]?%d+):(%d+):(%d+)$")
                            if l_off then
                                table.insert(data.__pivots, {l_off = tonumber(l_off), p_idx = tonumber(p_idx), t_pos = tonumber(t_pos)})
                            else
                                local single = tonumber(part)
                                if single then table.insert(data.__pivots, {l_off = 0, p_idx = single, t_pos = 1}) end
                            end
                        end
                    end
                    table.insert(new_highlights, data)
                end
            end
        end
    end
    f:close()
    
    FSM.ANKI_HIGHLIGHTS = new_highlights
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
end

local function show_osd(msg, dur)
    local style = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(style .. "{\\an4}{\\fs20}" .. msg, dur or Options.osd_duration)
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
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
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
local function dw_get_str_width(str)
    if type(str) == "table" then str = str.text end
    if not str then return 0 end
    
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

local function draw_drum(subs, center_idx, y_pos_percent, time_pos, font_size)
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
    
    local function format_sub(sub_idx, is_active, t_pos)
        local text = subs[sub_idx] and subs[sub_idx].text or ""
        if text == "" then return "" end
        local base_color = is_active and Options.drum_active_color or Options.drum_context_color
        local opacity = calculate_ass_alpha(is_active and Options.drum_active_opacity or Options.drum_context_opacity)
        local is_drum = (FSM.DRUM == "ON")
        local font_name = is_drum and (Options.drum_font_name ~= "" and Options.drum_font_name or mp.get_property("sub-font", "Inter"))
                                   or (Options.srt_font_name ~= "" and Options.srt_font_name or mp.get_property("sub-font", "Inter"))
        local f_bold = is_drum and Options.drum_font_bold or Options.srt_font_bold
        local bold_state = (is_active and (is_drum and Options.drum_active_bold or f_bold) 
                                      or (is_drum and Options.drum_context_bold or f_bold)) and "1" or "0"
        
        local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
        
        local tokens = build_word_list_internal(text, Options.dw_original_spacing)
        
        -- Build logical word map to ensure parity with calculate_highlight_stack
        local logical_to_visual = {}
        local visual_to_logical = {}
        local logic_count = 0
        for j, t in ipairs(tokens) do
            if is_word_token(t) then
                logic_count = logic_count + 1
                logical_to_visual[logic_count] = j
                visual_to_logical[j] = logic_count
            end
        end

        -- Level 1 & 2: Base Highlighting (First Pass)
        local token_meta = {}
        for j, t in ipairs(tokens) do
            local l_idx = visual_to_logical[j]
            local meta = { text = t.text, color = base_color, is_word = t.is_word, is_phrase = false, priority = 0 }
            
            -- Level 1: Persistent Selection
            local ctrl_member = l_idx and FSM.DW_CTRL_PENDING_SET[string.format("%d:%d", sub_idx, l_idx)] or nil
            if ctrl_member then
                meta.color = Options.dw_ctrl_select_color
                meta.priority = 1
            end

            -- Level 2: Selection/Hover (Focus Point)
            if meta.priority == 0 and l_idx then
                local is_focus_point = (sub_idx == FSM.DW_CURSOR_LINE and l_idx == FSM.DW_CURSOR_WORD)
                if is_focus_point then
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

                if prev_meta and prev_meta.priority == 3 and prev_meta.is_phrase then
                    if (next_meta and next_meta.priority == 3 and next_meta.color == prev_meta.color) or (not next_meta or not next_meta.is_word) then
                        meta.color = prev_meta.color
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

    local prev_text = ""
    for i = start_idx, center_idx - 1 do
        local sub = subs[i]
        prev_text = prev_text .. (prev_text == "" and "" or "\\N") .. format_sub(i, false, sub.start_time)
    end
    
    local active_text = ""
    if center_idx > 0 and center_idx <= #subs then
        local sub = subs[center_idx]
        -- The centered line in draw_drum is always considered "active" (highlighted white),
        -- which ensures consistent highlighting during scrolling and seek operations,
        -- matching the robust behavior of the Drum Window (Mode W).
        active_text = format_sub(center_idx, true, sub.start_time)
    end
    
    local next_text = ""
    for i = center_idx + 1, end_idx do
        local sub = subs[i]
        next_text = next_text .. (next_text == "" and "" or "\\N") .. format_sub(i, false, sub.start_time)
    end
    
    local all_text = prev_text
    if all_text ~= "" and active_text ~= "" then all_text = all_text .. "\\N" end
    all_text = all_text .. active_text
    if all_text ~= "" and next_text ~= "" then all_text = all_text .. "\\N" end
    all_text = all_text .. next_text

    local style_block = string.format("{\\bord%g}{\\shad%g}{\\4a&H%s&}", 
        Options.drum_border_size, Options.drum_shadow_offset, calculate_ass_alpha(Options.drum_bg_opacity))

    if is_top then
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    else
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    end

    return ass
end


-- Unified layout engine: wraps subtitle words into visual lines
local function dw_build_layout(subs, view_center)
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

    local vline_h = Options.dw_font_size * Options.dw_vline_h_mul
    local sub_gap = Options.dw_font_size * Options.dw_sub_gap_mul
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
            if is_word_token(t) then
                table.insert(logical_words, t)
                local l_idx = #logical_words
                visual_to_logical[j] = l_idx
                logical_to_visual[l_idx] = j
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

    return layout, total_height
end

-- draw_dw: view_center = which line is in the center of the viewport
--          active_idx = which line is currently playing (colored blue, may be off-screen)
local function draw_dw(subs, view_center, active_idx)
    if not subs or #subs == 0 then return "" end
    
    local ass = ""
    local layout, total_height = dw_build_layout(subs, view_center)
    local sub_gap = Options.dw_font_size * Options.dw_sub_gap_mul
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
    for _, entry in ipairs(layout) do
        local i = entry.sub_idx
        FSM.DW_LINE_Y_MAP[i] = current_y + (entry.height / 2)
        current_y = current_y + entry.height + sub_gap
        
        local is_active = (i == active_idx)
        local color = is_active and Options.dw_active_color or Options.dw_text_color
        local font_name = (Options.dw_font_name ~= "") and Options.dw_font_name or mp.get_property("sub-font", "Inter")
        local bold_state = Options.dw_font_bold and "1" or "0"
        local line_prefix = string.format("{\\fn%s}{\\b%s}{\\c&H%s&}", font_name, bold_state, color)
        
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
                local ctrl_member = l_idx and FSM.DW_CTRL_PENDING_SET[string.format("%d:%d", i, l_idx)] or nil
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
                    local orange_stack, purple_stack, is_phrase = calculate_highlight_stack(subs, i, j, subs[i].start_time)
                    local h_color = color
                    
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

                    if h_color ~= color then
                        meta.color = h_color
                        meta.is_phrase = is_phrase
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

                    -- If internal punctuation within a phrase OR trailing a phrase and not followed by a word
                    if prev_meta and prev_meta.priority == 3 and prev_meta.is_phrase then
                        if (next_meta and next_meta.priority == 3 and next_meta.color == prev_meta.color) or (not next_meta or not next_meta.is_word) then
                            meta.color = prev_meta.color
                            meta.is_phrase = true
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
    
    -- Join separate subtitles with \N\N
    local block_text = table.concat(lines_ass, "\\N\\N")
    -- \q2 disables smart wrapping: forces screen layout to exactly match our dw_build_layout
    ass = ass .. string.format("{\\pos(960, 540)}{\\an5}{\\bord%g}{\\shad%g}{\\1a&H%s&}{\\4a&H%s&}{\\q2}{\\fs%d}%s", 
        Options.dw_border_size, Options.dw_shadow_offset, calculate_ass_alpha(Options.dw_text_opacity), calculate_ass_alpha(Options.dw_bg_opacity), Options.dw_font_size, block_text)
    
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
    
    local lines = {}
    for i = start_idx, end_idx do
        table.insert(lines, Tracks.sec.subs[i].raw_text)
    end
    local text = table.concat(lines, "\\N")
    
    local font_name = (Options.tooltip_font_name ~= "") and Options.tooltip_font_name or mp.get_property("sub-font", "Inter")
    local fs = Options.tooltip_font_size
    local bg_alpha = Options.tooltip_bg_opacity
    local bg_color = Options.tooltip_bg_color
    local text_color = Options.tooltip_text_color
    local text_alpha = Options.tooltip_text_opacity or "00"
    local bold = Options.tooltip_font_bold and "1" or "0"
    local bord = Options.tooltip_border_size or 1.5
    local shad = Options.tooltip_shadow_offset or 1.0

    local ass = string.format("{\\fn%s}{\\pos(1800, %d)}{\\an6}{\\fs%d}{\\b%s}{\\bord%g}{\\shad%g}{\\1c&H%s&}{\\1a&H%s&}{\\3c&H%s&}{\\4a&H%s&}{\\q1}%s",
        font_name, osd_y, fs, bold, bord, shad, text_color, calculate_ass_alpha(text_alpha), bg_color, calculate_ass_alpha(bg_alpha), text)
        
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

    local vline_h = Options.dw_font_size * Options.dw_vline_h_mul
    local sub_gap = Options.dw_font_size * Options.dw_sub_gap_mul
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
                if k < #vl_indices and not Options.dw_original_spacing then 
                    vl_width = vl_width + space_w 
                end
            end
            
            local vl_left = 960 - vl_width / 2

            local cx = osd_x - vl_left
            if cx < 0 then return entry.sub_idx, entry.visual_to_logical[vl_indices[1]] or 1 end
            if cx >= vl_width then return entry.sub_idx, entry.visual_to_logical[vl_indices[#vl_indices]] or #entry.words end

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
    return last.sub_idx, last_vl[#last_vl]
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

local function dw_sync_cursor_to_mouse()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx = dw_hit_test(osd_x, osd_y)

    if line_idx and word_idx then
        -- Selection & Hover Protection: ONLY update logical cursor if we ARE dragging.
        -- This prevents the active highlight from snapping to the mouse while scrolling
        -- unless the user is consciously selecting something.
        if FSM.DW_MOUSE_DRAGGING then
            FSM.DW_CURSOR_LINE = line_idx
            FSM.DW_CURSOR_WORD = word_idx
        end

        local active_idx = get_center_index(subs, mp.get_property_number("time-pos") or 0)
        dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
        dw_osd:update()
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
    if FSM.DRUM_WINDOW == "OFF" then return end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, _ = dw_hit_test(osd_x, osd_y)
    
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
            local indices = {}
            local pivot_idx = 1
            for i = p1_l, p2_l do
                local sub = subs[i]
                if sub then
                    local tokens = get_sub_tokens(sub)
                    local s_w = (i == p1_l) and p1_w or 1
                    local e_w = (i == p2_l) and p2_w or (sub.word_count or 0)
                    
                    local line_parts = {}
                    local in_range = false
                    for _, t in ipairs(tokens) do
                        if t.is_word then
                            if t.logical_idx == s_w then in_range = true end
                            if in_range then 
                                table.insert(line_parts, t.text) 
                                table.insert(indices, string.format("%d:%d:%d", i - p1_l, t.logical_idx, pivot_idx))
                                pivot_idx = pivot_idx + 1
                            end
                            if t.logical_idx == e_w then in_range = false break end
                        elseif in_range then
                            table.insert(line_parts, t.text)
                        end
                    end
                    
                    if #line_parts > 0 then
                        table.insert(parts, table.concat(line_parts, ""))
                    end
                end
            end
            term = table.concat(parts, " ")
            advanced_index = table.concat(indices, ",")
            
            local ctx_parts = {}
            pivot_pos = 0
            local start_k = math.max(1, p1_l - Options.anki_context_lines)
            for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines) do
                if subs[k] then 
                    local text = subs[k].text
                    table.insert(ctx_parts, text)
                    
                    local cleaned = text:gsub("{[^}]+}", "")
                    if Options.anki_strip_metadata then cleaned = cleaned:gsub("%b[]", " ") end
                    cleaned = cleaned:gsub("%s+", " ")
                    
                    if k < p1_l then
                        pivot_pos = pivot_pos + #cleaned + 1
                    elseif k == p1_l then
                        pivot_pos = pivot_pos + (#cleaned / 2)
                    end
                end
            end
            context_line = table.concat(ctx_parts, " ")
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
                if prev_text and prev_text:match("[.!?]$") then
                    is_sentence_boundary = true
                end
            end
        elseif cl ~= -1 and subs[cl] then
            local target_sub = subs[cl]
            local ctx_parts = {}
            pivot_pos = 0
            local start_k = math.max(1, cl - Options.anki_context_lines)
            for k = start_k, math.min(#subs, cl + Options.anki_context_lines) do
                if subs[k] then 
                    local text = subs[k].text
                    table.insert(ctx_parts, text)
                    
                    local cleaned = text:gsub("{[^}]+}", "")
                    if Options.anki_strip_metadata then cleaned = cleaned:gsub("%b[]", " ") end
                    cleaned = cleaned:gsub("%s+", " ")
                    
                    if k < cl then
                        pivot_pos = pivot_pos + #cleaned + 1
                    elseif k == cl then
                        pivot_pos = pivot_pos + (#cleaned / 2)
                    end
                end
            end
            context_line = table.concat(ctx_parts, " ")
            -- Add small epsilon (1ms) to ensure grounding lands inside this segment
            time_pos = target_sub.start_time + 0.001
            p1_w = cw
            p1_l = cl
            print(string.format("[LLS] Export Point: Line %d, Word Index: %d, Pivot: %.1f", cl, cw, pivot_pos))
            local tokens = get_sub_tokens(target_sub)
            local words = {}
            for _, t in ipairs(tokens) do if t.is_word then table.insert(words, t.text) end end
            print("[LLS] Word List: " .. table.concat(words, " | ", 1, math.min(10, #words)))
            
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
                advanced_index = string.format("0:%d:1", cw)
                -- Check for boundary
                if cw == 1 or (prev_text and prev_text:match("[.!?]$")) then
                    is_sentence_boundary = true
                end
            else
                term = target_sub.text
                is_sentence_boundary = true
            end
        end

        if term and term ~= "" then
            -- Clean term: remove ASS tags and trim whitespace
            term = term:gsub("{[^}]+}", "")
            if Options.anki_strip_metadata then
                local stripped = term:gsub("%b[]", " ")
                if stripped:match("%S") then
                    term = stripped
                else
                    -- It's all bracketed. Preserve content but strip brackets.
                    term = term:gsub("[%[%]]", "")
                end
            end
            term = term:gsub("%s+", " "):match("^%s*(.-)%s*$")
            
            -- Clean capture: Remove leading/trailing punctuation (including hyphens and slashes)
            local pre = term:match("^[%p%s]*")
            local suf = term:match("[%p%s]*$")
            local raw_had_terminal = term:match("[.!?][%s%p]*$") ~= nil
            if #pre < #term then
                term = term:sub(#pre + 1, #term - #suf)
            end
            -- If the selection starts at a boundary AND original subtitle ended with a period (or ! or ?) AND
            -- the cleaned term starts with an uppercase letter AND contains spaces (multi-word), restore the period.
            if is_sentence_boundary and raw_had_terminal and starts_with_uppercase(term) and term:find(" ") and not term:match("[.!?]$") then
                term = term .. "."
            end
            
            -- Clean context: remove ASS tags
            context_line = context_line:gsub("{[^}]+}", "")
            if Options.anki_strip_metadata then
                context_line = context_line:gsub("%b[]", " ")
            end
            context_line = context_line:gsub("%s+", " ")
            local term_words = build_word_list(term)
            local effective_limit = math.max(Options.anki_context_max_words, #term_words + 20)
            local extracted_context = extract_anki_context(context_line, term, effective_limit, pivot_pos)
            -- Use the multi-index generated above
            save_anki_tsv_row(term, extracted_context, time_pos, advanced_index)
            show_osd("Anki Highlight Saved: " .. term)

            
            -- Force reload of TSV to pick up the new highlight and clear selection to show it
            load_anki_tsv(true)
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_WORD = -1
            
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
    if not next(FSM.DW_CTRL_PENDING_SET) then return end
    FSM.DW_CTRL_PENDING_SET = {}
    dw_osd:update()
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
    if line_idx < 1 or word_idx < 1 then return end
    
    local key = string.format("%d:%d", line_idx, word_idx)
    if FSM.DW_CTRL_PENDING_SET[key] then
        FSM.DW_CTRL_PENDING_SET[key] = nil
    else
        FSM.DW_CTRL_PENDING_SET[key] = {line = line_idx, word = word_idx}
    end
    dw_osd:update()
end

local function ctrl_commit_set(line_idx, word_idx)
    -- Check if cursor word is in set
    local key = string.format("%d:%d", line_idx, word_idx)
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
            if not sub.words then sub.words = build_word_list(sub.text) end
            local w = sub.words[m.word]
            if w then
                local clean_w = w
                if Options.anki_strip_metadata and clean_w:match("^%b[]$") then
                    clean_w = clean_w:gsub("[%[%]]", "")
                end

                if last_m then
                    local is_gap = false
                    if m.line > last_m.line then
                        -- Bridging line boundary: It's a gap if we skipped words at end of last_m.line 
                        -- or words at start of m.line. But simple sets (Ctrl+MMB) are almost always gaps.
                        -- However, for the contiguous engine to recognize it, we must join with space.
                        local last_line_wc = subs[last_m.line].word_count or 0
                        if (m.line > last_m.line + 1) or (last_m.word < last_line_wc) or (m.word > 1) then
                            is_gap = true
                        end
                    elseif m.word > last_m.word + 1 then
                        is_gap = true
                    end

                    if is_gap then
                        -- Inject space-padded ellipsis for non-contiguous selections
                        term = term .. " ... "
                    else
                        -- Use smart joiner logic for contiguous words
                        local next_w = clean_w
                        local prev_w = term:match("%S+$") or ""
                        
                        local no_space_before = next_w:match("[%.,!?;:…»”%)%]%}]$") 
                                              or next_w:match("^[/-]$") 
                                              or next_w:match("^\226\128\147$") 
                                              or next_w:match("^\226\128\148$") 
                                              or next_w:match("^[\"']$")
                        
                        local no_space_after = prev_w:match("^[/-]$") 
                                             or prev_w:match("^\226\128\147$") 
                                             or prev_w:match("^\226\128\148$") 
                                             or prev_w:match("^[%[%({¿¡«„“]$")
                                             or prev_w:match("^[\"']$")
                        
                        if not (no_space_before or no_space_after) then
                            term = term .. " "
                        end
                    end
                end
                term = term .. clean_w
                last_m = m
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
    for i, m in ipairs(members) do
        local l_off = m.line - members[1].line
        table.insert(indices, string.format("%d:%d:%d", l_off, m.word, i))
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

            -- Dismiss tooltip on click and lock suppression for the current focus
            local osd_x, osd_y = dw_get_mouse_osd()
            local line_idx, word_idx = dw_hit_test(osd_x, osd_y)
            
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
                    if is_shift then
                        if FSM.DW_ANCHOR_LINE == -1 then
                            FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
                            FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
                        end
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    elseif on_up_callback and is_inside_dw_selection(line_idx, word_idx) then
                        -- Preserve selection for commit
                    else
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_ANCHOR_LINE = line_idx
                        FSM.DW_ANCHOR_WORD = word_idx
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    end
                    
                    -- Phase 3: Dragging (Only for selection/shift)
                    FSM.DW_MOUSE_DRAGGING = true
                    mp.add_forced_key_binding("mouse_move", "dw-mouse-drag", dw_mouse_update_selection)
                    if FSM.DW_MOUSE_SCROLL_TIMER then FSM.DW_MOUSE_SCROLL_TIMER:kill() end
                    FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(0.05, dw_mouse_auto_scroll)
                    
                    drum_osd:update()
                    if dw_osd then dw_osd:update() end
                end
            end
        elseif tbl.event == "up" then
            FSM.DW_MOUSE_DRAGGING = false
            
            -- Release suppression release lock if we were dragging
            local line_idx, _ = dw_hit_test(dw_get_mouse_osd())
            if updates_selection then
                FSM.DW_TOOLTIP_LOCKED_LINE = line_idx or -1
            end

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
        local a_key = string.format("%d:%d", FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD)
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
                local s_w = (i == p1_l) and p1_w or 1
                local e_w = (i == p2_l) and p2_w or (sub.word_count or 0)
                for w = s_w, e_w do
                    ctrl_toggle_word(i, w)
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
        dw_osd:update()
    else
        -- Fallback to single word toggle (standard behavior)
        if was_mouse then
            local osd_x, osd_y = dw_get_mouse_osd()
            line, word = dw_hit_test(osd_x, osd_y)
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
    local line_idx, word_idx = dw_hit_test(osd_x, osd_y)
    if not line_idx then return end

    local sub = subs[line_idx]
    if sub and sub.start_time then
        mp.commandv("seek", sub.start_time, "absolute+exact")
        FSM.DW_CURSOR_LINE = line_idx
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        
        if not FSM.BOOK_MODE then
            FSM.DW_VIEW_CENTER = line_idx
        end
        
        FSM.DW_FOLLOW_PLAYER = not FSM.BOOK_MODE
    end
end

local function tick_dw(time_pos)
    local subs = Tracks.pri.subs
    if #subs == 0 then return end
    
    local active_idx = get_center_index(subs, time_pos)
    if active_idx == -1 then return end
    FSM.DW_ACTIVE_LINE = active_idx
    
    -- In follow mode: viewport tracks playback; cursor only tracks if no range selection is active
    if FSM.DW_FOLLOW_PLAYER and not FSM.BOOK_MODE then
        FSM.DW_VIEW_CENTER = active_idx
        if FSM.DW_ANCHOR_LINE == -1 then
            FSM.DW_CURSOR_LINE = active_idx
        end
    end
    -- In manual mode: DW_VIEW_CENTER and DW_CURSOR_LINE are frozen,
    -- active_idx just controls the blue highlight color (may be off-screen)
    
    dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
    dw_osd:update()
    
    dw_tooltip_mouse_update()
end

local function tick_drum(time_pos)
    -- Don't render Drum Mode OSD while Drum Window is open (they overlap)
    if FSM.DRUM_WINDOW ~= "OFF" then return end
    
    local is_drum = (FSM.DRUM == "ON")
    local vis = FSM.native_sub_vis
    
    if not vis then
        drum_osd.data = ""
        drum_osd:update()
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
        local max_pixels = max_lines * font_size * Options.drum_stack_multiplier
        -- Calculate safety position (2 blocks above primary + comfort gap)
        local min_safe_pos = pri_pos - (2 * (max_pixels / 1080) * 100) - Options.drum_track_gap
        -- Apply relative offset so user keys (r/t) still work responsively
        local auto_offset = min_safe_pos - Options.sec_pos_bottom
        sec_pos = sec_pos + auto_offset
    end

    -- Draw Primary FIRST, Secondary SECOND (so Secondary is on top in Z-order)
    if #Tracks.pri.subs > 0 then
        local idx = get_center_index(Tracks.pri.subs, time_pos)
        ass_text = ass_text .. draw_drum(Tracks.pri.subs, idx, pri_pos, time_pos, font_size)
    end

    if #Tracks.sec.subs > 0 then
        local idx = get_center_index(Tracks.sec.subs, time_pos)
        ass_text = ass_text .. draw_drum(Tracks.sec.subs, idx, sec_pos, time_pos, font_size)
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
    local ok, err = xpcall(function()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    -- Execute Autopause
    if FSM.AUTOPAUSE == "ON" and FSM.SPACEBAR == "IDLE" then
        tick_autopause(time_pos)
    end

    -- Manage native subtitle suppression
    -- We hide native subs if OSD rendering is active OR Drum Window is open.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local render_osd = FSM.native_sub_vis and (FSM.DRUM == "ON" or use_osd_for_srt)
    local dw_active = (FSM.DRUM_WINDOW ~= "OFF")

    if dw_active or render_osd then
        if mp.get_property_bool("sub-visibility") or mp.get_property_bool("secondary-sub-visibility") then
            mp.set_property_bool("sub-visibility", false)
            mp.set_property_bool("secondary-sub-visibility", false)
        end
        
        -- Only render one-line Drum/SRT OSD if Drum Window is not active
        if not dw_active and render_osd then
            tick_drum(time_pos)
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
        tick_dw(time_pos)
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

        show_osd("Drum Mode: ON")
    else
        FSM.DRUM = "OFF"
        show_osd("Drum Mode: OFF")
    end
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


local function cmd_dw_line_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    FSM.DW_FOLLOW_PLAYER = false
    
    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = (FSM.DW_CURSOR_WORD > 0) and FSM.DW_CURSOR_WORD or 1
    end
    
    FSM.DW_CURSOR_LINE = math.max(1, math.min(#subs, FSM.DW_CURSOR_LINE + dir))
    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    
    local half = math.floor(Options.dw_lines_visible / 2)
    local view_min = FSM.DW_VIEW_CENTER - half
    local view_max = view_min + Options.dw_lines_visible - 1
    
    if FSM.DW_CURSOR_LINE < view_min then
        FSM.DW_VIEW_CENTER = math.max(1, FSM.DW_CURSOR_LINE + half)
    elseif FSM.DW_CURSOR_LINE > view_max then
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

local function cmd_dw_word_move(dir, shift)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    FSM.DW_FOLLOW_PLAYER = false
    
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
    
    if not shift then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
    elseif FSM.DW_ANCHOR_WORD == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD - dir 
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
    
    local target_idx = math.max(1, math.min(#subs, current_idx + dir))
    local sub = subs[target_idx]
    if sub and sub.start_time then
        mp.commandv("seek", sub.start_time, "absolute+exact")
        FSM.DW_FOLLOW_PLAYER = not FSM.BOOK_MODE
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        
        if not FSM.BOOK_MODE then
            FSM.DW_VIEW_CENTER = target_idx
            if FSM.DW_ANCHOR_LINE == -1 then
                FSM.DW_CURSOR_LINE = target_idx
                FSM.DW_CURSOR_WORD = -1
            end
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
        cmd_dw_seek_delta(dir)
        
        -- Setup repeat timer
        if FSM.SEEK_REPEAT_TIMER then FSM.SEEK_REPEAT_TIMER:kill() end
        FSM.SEEK_REPEAT_TIMER = mp.add_timeout(Options.seek_hold_delay, function()
            FSM.SEEK_REPEAT_TIMER = mp.add_periodic_timer(1.0 / Options.seek_hold_rate, function()
                cmd_dw_seek_delta(dir)
            end)
        end)
    elseif table.event == "up" then
        if FSM.SEEK_REPEAT_TIMER then
            FSM.SEEK_REPEAT_TIMER:kill()
            FSM.SEEK_REPEAT_TIMER = nil
        end
    end
end

local function manage_dw_bindings(enable)
    local function nav(fn, key_name)
        return function(t)
            -- Ignore modifiers (Ctrl, Shift, Alt, Meta) as shield-triggers so combos like Shift+Click work.
            -- Navigation/Action keys (Arrows, Enter, etc.) still trigger the 150ms mouse lockout.
            local key = (t and t.key) or key_name or ""
            if not (key == "Ctrl" or key == "Shift" or key == "Alt" or key == "Meta") then
                FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + 0.150
            end
            return fn(t)
        end
    end

    local keys = {
        {key = "LEFT", name = "dw-word-left", fn = nav(function() cmd_dw_word_move(-1, false) end, "LEFT")},
        {key = "RIGHT", name = "dw-word-right", fn = nav(function() cmd_dw_word_move(1, false) end, "RIGHT")},
        {key = "UP", name = "dw-line-up", fn = nav(function() cmd_dw_line_move(-1, false) end, "UP")},
        {key = "DOWN", name = "dw-line-down", fn = nav(function() cmd_dw_line_move(1, false) end, "DOWN")},
        {key = "Shift+UP", name = "dw-line-up-shift", fn = nav(function() cmd_dw_line_move(-1, true) end, "Shift+UP")},
        {key = "Shift+DOWN", name = "dw-line-down-shift", fn = nav(function() cmd_dw_line_move(1, true) end, "Shift+DOWN")},
        {key = "a", name = "dw-seek-back", fn = nav(function(t) cmd_seek_with_repeat(-1, t) end, "a"), complex = true},
        {key = "d", name = "dw-seek-fwd", fn = nav(function(t) cmd_seek_with_repeat(1, t) end, "d"), complex = true},
        {key = "ENTER", name = "dw-enter", fn = nav(function() cmd_dw_seek_selected() end, "ENTER")},
        {key = "KP_ENTER", name = "dw-enter-kp", fn = nav(function() cmd_dw_seek_selected() end, "KP_ENTER")},
        {key = "Shift+LEFT", name = "dw-word-left-shift", fn = nav(function() cmd_dw_word_move(-1, true) end, "Shift+LEFT")},
        {key = "Shift+RIGHT", name = "dw-word-right-shift", fn = nav(function() cmd_dw_word_move(1, true) end, "Shift+RIGHT")},
        {key = "Ctrl+LEFT", name = "dw-word-left-ctrl", fn = nav(function() cmd_dw_word_move(-5, false) end, "Ctrl+LEFT")},
        {key = "Ctrl+RIGHT", name = "dw-word-right-ctrl", fn = nav(function() cmd_dw_word_move(5, false) end, "Ctrl+RIGHT")},
        {key = "Ctrl+Shift+LEFT", name = "dw-word-left-ctrl-shift", fn = nav(function() cmd_dw_word_move(-5, true) end, "Ctrl+Shift+LEFT")},
        {key = "Ctrl+Shift+RIGHT", name = "dw-word-right-ctrl-shift", fn = nav(function() cmd_dw_word_move(5, true) end, "Ctrl+Shift+RIGHT")},
        {key = "Ctrl+Shift+UP", name = "dw-line-up-ctrl-shift", fn = nav(function() cmd_dw_line_move(-5, true) end, "Ctrl+Shift+UP")},
        {key = "Ctrl+Shift+DOWN", name = "dw-line-down-ctrl-shift", fn = nav(function() cmd_dw_line_move(5, true) end, "Ctrl+Shift+DOWN")},
        {key = "WHEEL_UP", name = "dw-scroll-up", fn = function() cmd_dw_scroll(-1) end},
        {key = "WHEEL_DOWN", name = "dw-scroll-down", fn = function() cmd_dw_scroll(1) end},
        {key = "Ctrl+UP", name = "dw-scroll-up-ctrl", fn = nav(function() cmd_dw_scroll(-1) end, "Ctrl+UP")},
        {key = "Ctrl+DOWN", name = "dw-scroll-down-ctrl", fn = nav(function() cmd_dw_scroll(1) end, "Ctrl+DOWN")},
        {key = "ESC", name = "dw-close", fn = nav(function() cmd_toggle_drum_window() end, "ESC")},
        {key = "Ctrl+ESC", name = "dw-pair-discard", fn = nav(ctrl_discard_set, "Ctrl+ESC")},
        {key = "Ctrl+c", name = "dw-copy", fn = nav(function() cmd_dw_copy() end, "Ctrl+c")},
        -- Mouse selection & Suppression
        {key = "Shift+MBTN_LEFT", name = "dw-mouse-select-shift", fn = cmd_dw_mouse_select_shift, complex = true},
        {key = "MBTN_LEFT_DBL", name = "dw-mouse-dblclick", fn = cmd_dw_double_click},
        -- Ctrl Tracking (State mapping)
        {key = "Ctrl", name = "dw-ctrl-track", fn = nav(function(t) 
            FSM.DW_CTRL_HELD = (t.event == "down" or t.event == "repeat")
            -- We no longer discard on Ctrl up to allow building pink selections with modifier keys
        end, "Ctrl"), complex = true},
    }

    local function parse_and_bind(key_string, base_name, mouse_fn, key_fn, updates_selection)
        if not key_string or key_string == "" then return end
        local i = 1
        for key in key_string:gmatch("[^%s,;]+") do
            if key ~= "" then
                local is_mouse = key:find("MBTN_") or key:find("WHEEL")
                if is_mouse then
                    -- Detect if the handler is already a mouse handler to avoid redundant wrapping
                    if mouse_fn and MOUSE_HANDLERS[mouse_fn] then
                        table.insert(keys, {
                            key = key,
                            name = base_name .. "-" .. i,
                            fn = mouse_fn,
                            complex = true
                        })
                    else
                        -- Mouse keys get the full drag/drop treatment via make_mouse_handler
                        local m_fn = make_mouse_handler(false, 
                            function(t) mouse_fn(t, true) end, -- up
                            function(t) mouse_fn(t, true) end, -- down
                            updates_selection
                        )
                        table.insert(keys, {
                            key = key,
                            name = base_name .. "-" .. i,
                            fn = m_fn,
                            complex = true
                        })
                    end
                else
                    table.insert(keys, {
                        key = key,
                        name = base_name .. "-" .. i,
                        fn = function(t) 
                            -- Shield the mouse from ghost clicks for 150ms when a key is pressed
                            FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + 0.150
                            key_fn(t, false) 
                        end,
                        complex = false
                    })
                end
                i = i + 1
            end
        end
    end

    parse_and_bind(Options.dw_key_add, "dw-add", cmd_dw_export_anki, cmd_dw_add_smart, true)
    parse_and_bind(Options.dw_key_pair, "dw-pair", cmd_dw_toggle_pink, cmd_dw_toggle_pink, true)
    parse_and_bind(Options.dw_key_select, "dw-select", cmd_dw_mouse_select, function() end, true)
    parse_and_bind(Options.dw_key_tooltip_pin, "dw-tooltip-pin", cmd_dw_tooltip_pin, cmd_dw_tooltip_pin, false)
    parse_and_bind(Options.dw_key_tooltip_hover, "dw-tooltip-hover", cmd_toggle_dw_tooltip_hover, cmd_toggle_dw_tooltip_hover, false)
    parse_and_bind(Options.dw_key_tooltip_toggle, "dw-tooltip-toggle", cmd_dw_tooltip_toggle, cmd_dw_tooltip_toggle, false)

    -- Extra Layout & Search
    local extra = {
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
        {key = "ф", name = "dw-seek-back-ru", fn = function(t) cmd_seek_with_repeat(-1, t) end, complex = true},
        {key = "в", name = "dw-seek-fwd-ru", fn = function(t) cmd_seek_with_repeat(1, t) end, complex = true},
        {key = "ENTER", name = "dw-enter-ru", fn = function() cmd_dw_seek_selected() end},
        {key = "Ctrl+ЛЕВЫЙ", name = "dw-word-left-ctrl-ru", fn = function() cmd_dw_word_move(-5, false) end},
        {key = "Ctrl+ПРАВЫЙ", name = "dw-word-right-ctrl-ru", fn = function() cmd_dw_word_move(5, false) end},
        {key = "Ctrl+Shift+ЛЕВЫЙ", name = "dw-word-left-ctrl-shift-ru", fn = function() cmd_dw_word_move(-5, true) end},
        {key = "Ctrl+Shift+ПРАВЫЙ", name = "dw-word-right-ctrl-shift-ru", fn = function() cmd_dw_word_move(5, true) end},
        {key = "Ctrl+Shift+ВВЕРХ", name = "dw-line-up-ctrl-shift-ru", fn = function() cmd_dw_line_move(-5, true) end},
        {key = "Ctrl+Shift+ВНИЗ", name = "dw-line-down-ctrl-shift-ru", fn = function() cmd_dw_line_move(5, true) end},
        {key = "Ctrl+с", name = "dw-copy-ru", fn = function() cmd_dw_copy() end},
        {key = "Ctrl+f", name = "dw-search-toggle", fn = function() cmd_toggle_search() end},
        {key = "Ctrl+а", name = "dw-search-toggle-ru", fn = function() cmd_toggle_search() end},
    }
    for _, k in ipairs(extra) do table.insert(keys, k) end

    for _, k in ipairs(keys) do
        if enable then 
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
        -- Flush tooltip
        FSM.DW_TOOLTIP_LINE = -1
        dw_tooltip_osd.data = ""
        dw_tooltip_osd:update()
    else
        FSM.DW_NATIVE_WINDOW_DRAGGING = mp.get_property_bool("window-dragging", true)
        mp.set_property_bool("window-dragging", false)
    end
    FSM.DW_KEY_OVERRIDE = enable
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
    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord2}{\\3c&H%s&}{\\1c&H%s&}{\\alpha&H11&}{\\4a&HFF&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
        box_x, box_y, border_color, bg_color, bg_color, box_w, box_w, line_height + padding_y * 2, line_height + padding_y * 2)
    
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

    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&HFF&}{\\fs%d}{\\c&H%s&} %s\n",
        box_x + padding_x, box_y + padding_y, font_size, text_color, display_query)
        
    -- Draw Results Dropdown
    if #FSM.SEARCH_RESULTS > 0 then
        local max_results_display = 8
        local display_count = math.min(#FSM.SEARCH_RESULTS, max_results_display)
        local results_h = display_count * line_height + padding_y * 2
        local results_y = box_y + line_height + padding_y * 2 + 5
        
        -- Dropdown Backing
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord2}{\\3c&H%s&}{\\1c&H%s&}{\\alpha&H22&}{\\4a&HFF&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, border_color, bg_color, bg_color, box_w, box_w, results_h, results_h)
            
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
            
            ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&HFF&}{\\fs%d}{\\c&H%s&} %s%s%s\n",
                box_x + padding_x, item_y, font_size * 0.8, base_color, sel_bold, display_text, sel_bold_end)
        end
    elseif FSM.SEARCH_QUERY ~= "" then
        -- "No results"
        local results_h = line_height + padding_y * 2
        local results_y = box_y + line_height + padding_y * 2 + 5
        
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord2}{\\3c&H%s&}{\\1c&H%s&}{\\alpha&H22&}{\\4a&HFF&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, border_color, bg_color, bg_color, box_w, box_w, results_h, results_h)
        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&HFF&}{\\fs%d}{\\c&H%s&} No results found.\n",
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

local function manage_ui_border_override(enable)
    -- Deprecated: We now rely on \4a&HFF& in ASS to hide background box.
    -- Kept to avoid breaking existing bindings/calls.
end

local function manage_search_bindings(enable)
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
                local selected_line = FSM.SEARCH_RESULTS[FSM.SEARCH_SEL_IDX].idx
                local sub = Tracks.pri.subs[selected_line]
                
                if sub.start_time then
                    mp.commandv("seek", sub.start_time, "absolute+exact")
                    FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
                end
                
                -- Update DW state so if it opens, or is open, it jumps to this line
                FSM.DW_CURSOR_LINE = selected_line
                FSM.DW_CURSOR_WORD = -1
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
        mp.add_forced_key_binding("Ctrl+v", "search-paste", paste_from_clipboard, "repeatable")
        mp.add_forced_key_binding("Ctrl+м", "search-paste-ru", paste_from_clipboard, "repeatable")
        
        local function select_all()
            FSM.SEARCH_ANCHOR = 0
            FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
            render_search()
        end
        mp.add_forced_key_binding("Ctrl+a", "search-select-all", select_all)
        mp.add_forced_key_binding("Ctrl+ф", "search-select-all-ru", select_all)
        
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
        mp.add_forced_key_binding("Ctrl+w", "search-delete-word", delete_word_before_cursor, "repeatable")
        mp.add_forced_key_binding("Ctrl+ц", "search-delete-word-ru", delete_word_before_cursor, "repeatable")
        
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
        mp.add_forced_key_binding("MBTN_LEFT", "search-mouse-click", search_mouse_click, {complex = true})
        
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
        mp.remove_key_binding("search-select-all")
        mp.remove_key_binding("search-select-all-ru")
        mp.remove_key_binding("search-delete-word")
        mp.remove_key_binding("search-delete-word-ru")
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
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_FOLLOW_PLAYER = true
        
        if not FSM.SEARCH_MODE then
            manage_dw_bindings(true)
        end

        -- Explicitly trigger first render for instant appearance
        if FSM.DRUM_WINDOW == "DOCKED" then
            tick_dw(time_pos or 0)
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
            manage_dw_bindings(false)
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
                if t.is_word then
                    if t.logical_idx == s_w then in_range = true end
                    if in_range then table.insert(line_parts, t.text) end
                    if t.logical_idx == e_w then in_range = false break end
                elseif in_range then
                    table.insert(line_parts, t.text)
                end
            end
            
            if #line_parts > 0 then
                table.insert(parts, table.concat(line_parts, ""))
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
        -- Clean capture: Remove trailing/leading punctuation/spaces
        local pre = final_text:match("^[%p%s]*")
        local suf = final_text:match("[%p%s]*$")
        if #pre < #final_text then
            final_text = final_text:sub(#pre + 1, #final_text - #suf)
        end
        
        set_clipboard(final_text)
        show_osd("DW Copied: " .. final_text:sub(1, 40) .. (#final_text > 40 and "..." or ""))
    end
end

local function cmd_toggle_sub_vis()
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
    
    show_osd("Subtitles: " .. (nxt and "ON" or "OFF"))
    drum_osd:update()
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
-- COPY CONTEXT LOGIC
-- =========================================================================

local function cmd_cycle_copy_mode()
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
                
                if #valid == 0 then table.insert(valid, (FSM.COPY_MODE == "A") and lines[#lines] or lines[1]) end
            else
                table.insert(valid, (FSM.COPY_MODE == "A") and lines[#lines] or lines[1])
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
mp.add_forced_key_binding("b", "book-mode-b", toggle_book_mode)
mp.add_forced_key_binding("и", "book-mode-ru", toggle_book_mode)
mp.add_key_binding(nil, "lls-seek_prev", function(t) cmd_seek_with_repeat(-1, t) end, {complex = true})
mp.add_key_binding(nil, "lls-seek_next", function(t) cmd_seek_with_repeat(1, t) end, {complex = true})
mp.add_key_binding(nil, "toggle-anki-global", cmd_toggle_anki_global)
mp.add_key_binding(nil, "toggle-record-file", function()
    if FSM.DRUM_WINDOW ~= "OFF" then
        cmd_open_record_file()
    end
end)

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
