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
    dw_font_size = 34,
    dw_lines_visible = 15,        -- how many lines visible in the window
    dw_bg_color = "A9C5D4",       -- beige in BGR hex for ASS
    dw_bg_opacity = "10",         -- background opacity (00-FF, lower is more opaque in ASS alpha? No, 00 is opaque)
    dw_text_color = "1A1A1A",     -- dark text
    dw_active_color = "ff0000",   -- brighter bright blue in BGR
    dw_highlight_color = "0000bf",-- red highlight in BGR
    dw_font_name = "Consolas",    -- monospace font for perfect hit-testing
    dw_char_width = 0.5,         -- char width multiplier (0.5 is exact for Consolas)
    dw_vline_h_mul = 0.87,        -- visual line height = dw_font_size * this (calibrated for font 34, use 0.9 for font 30)
    dw_sub_gap_mul = 0.6,         -- gap between subtitles = dw_font_size * this (calibrated for font 34, use 0.6 for font 30)

    -- Search HUD Styling
    search_hit_color = "0000bf",       -- Match highlighting (BGR)
    search_hit_bold = false,            -- Bold matches?
    search_sel_color = "ff0000",       -- Selected line color (BGR)
    search_sel_bold = false,           -- Bold selected line?
    search_query_hit_color = "0000bf", -- Search bar text hits (Select All/Selection)
    search_query_hit_bold = false,      -- Bold search bar hits?

    -- Font Scaling (Ported from fixed_font.lua)
    font_scaling_enabled = true,
    font_base_height = 1080,
    font_base_scale = 1.0,
    font_scale_strength = 0.5,

    -- Drum Window Tooltip
    dw_tooltip_font_size = 34,
    dw_tooltip_context_lines = 1,
    dw_tooltip_bg_opacity = "30",
    dw_tooltip_bg_color = "000000",
    dw_tooltip_text_color = "FFFFFF",
    dw_tooltip_text_opacity = "00",
    dw_tooltip_bold = false,
    dw_tooltip_border_size = 1.5,
    dw_tooltip_shadow_offset = 1.0,
    dw_tooltip_pin_key = "MBTN_RIGHT",
    dw_tooltip_hover_key = "n",
    dw_tooltip_hover_key_ru = "т",

    -- Navigation Repeat
    seek_hold_delay = 0.5,
    seek_hold_rate = 10,

    -- Anki Highlighter
    dw_export_key = "MBTN_MID",
    anki_context_max_words = 20,
    anki_tsv_headers = "Term	Context",
    anki_highlight_depth_1 = "0075D1",
    anki_highlight_depth_2 = "005DAE",
    anki_highlight_depth_3 = "003A70",
    anki_global_highlight = false,
    anki_sync_period = 30,
    anki_context_lines = 3,
    anki_local_fuzzy_window = 10.0,
    anki_context_strict = true,
    anki_highlight_bold = false
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
    SEARCH_ANCHOR = -1,

    -- Transient UI State
    saved_osd_border_style = nil,

    -- Tooltip State
    DW_TOOLTIP_LINE = -1,
    DW_TOOLTIP_MODE = "CLICK",
    DW_TOOLTIP_HOLDING = false,
    DW_TOOLTIP_LOCKED_LINE = -1,

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

local function clean_text_srt(line)
    line = line:gsub("^\xEF\xBB\xBF", "")
    return line:gsub("\r", ""):gsub("<[^>]+>", "")
end

local function has_cyrillic(str)
    if not str then return false end
    return str:find("[\208\209]") ~= nil
end

local function build_word_list(text)
    local words = {}
    if not text then return words end
    for w in text:gmatch("%S+") do
        table.insert(words, (w))
    end
    return words
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
    local upper = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
    local lower = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
    local u_table = utf8_to_table(upper)
    local l_table = utf8_to_table(lower)
    for i = 1, #u_table do
        res = res:gsub(u_table[i], l_table[i])
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

local function calculate_highlight_stack(subs, sub_idx, word_idx, time_pos)
    if not next(FSM.ANKI_HIGHLIGHTS) or not subs or not subs[sub_idx] then return 0 end
    
    local function get_sub_words(s)
        if not s then return nil end
        if not s.words then s.words = build_word_list(s.text) end
        return s.words
    end

    local words = get_sub_words(subs[sub_idx])
    local target_word = words[word_idx]
    if not target_word then return 0 end
    local target_lower = utf8_to_lower(target_word:gsub("[%p%s]", ""))
    if target_lower == "" then return 0 end

    -- Helper to get a word relative to current word_idx across segment boundaries
    local function get_relative_word(rel_offset)
        local curr_sub_idx = sub_idx
        local current_words = get_sub_words(subs[curr_sub_idx])
        if not current_words then return nil end
        local target_rel_idx = word_idx + rel_offset
        
        local safety = 0
        while safety < 5 do
            safety = safety + 1
            if target_rel_idx >= 1 and target_rel_idx <= #current_words then
                return current_words[target_rel_idx]
            end
            
            if target_rel_idx > #current_words then
                local next_sub_idx = curr_sub_idx + 1
                if subs[next_sub_idx] and (subs[next_sub_idx].start_time - subs[curr_sub_idx].end_time < 1.5) then
                    target_rel_idx = target_rel_idx - #current_words
                    curr_sub_idx = next_sub_idx
                    current_words = get_sub_words(subs[curr_sub_idx])
                    if not current_words then return nil end
                else
                    return nil
                end
            elseif target_rel_idx < 1 then
                local prev_sub_idx = curr_sub_idx - 1
                if subs[prev_sub_idx] and (subs[curr_sub_idx].start_time - subs[prev_sub_idx].end_time < 1.5) then
                    local prev_words = get_sub_words(subs[prev_sub_idx])
                    if not prev_words then return nil end
                    target_rel_idx = target_rel_idx + #prev_words
                    curr_sub_idx = prev_sub_idx
                    current_words = prev_words
                else
                    return nil
                end
            end
        end
        return nil
    end
    
    local stack = 0
    local has_phrase = false
    local matched_terms = {}
    for _, data in ipairs(FSM.ANKI_HIGHLIGHTS) do
        local term_key = data.term
        if not matched_terms[term_key] then
            local match_found = false
            
            -- Performance: Lazy-cache all cleaned word lists and lower-case contexts
            if not data.__term_words then
                data.__term_words = build_word_list(utf8_to_lower(term_key))
                data.__term_words_clean = {}
                for _, w in ipairs(data.__term_words) do
                    table.insert(data.__term_words_clean, utf8_to_lower(w:gsub("[%p%s]", "")))
                end
                data.__term_key_lower = utf8_to_lower(term_key)
                data.__ctx_lower = utf8_to_lower(data.context)
            end
            local term_words = data.__term_words
            local term_clean = data.__term_words_clean
            
            -- Adaptive window: Give more time for long paragraphs (0.5s per word extra)
            local window = Options.anki_local_fuzzy_window
            if #term_words > 10 then
                window = window + (#term_words * 0.5)
            end

            if Options.anki_global_highlight or math.abs(time_pos - data.time) < window then
                if #term_words > 0 then
                    local term_lower = data.__term_key_lower
                    local ctx_lower = data.__ctx_lower

                    -- Check all occurrences of target_lower in the term
                    for term_offset, tw_clean in ipairs(term_clean) do
                        if tw_clean == target_lower then
                            local sequence_match = true
                            
                            -- Phase 1: Local Sequence Match (verify ±3 words of context around the match)
                            if #term_words > 1 then
                                local check_start = math.max(1, term_offset - 3)
                                local check_end = math.min(#term_words, term_offset + 3)
                                for k = check_start, check_end do
                                    if k ~= term_offset then
                                        local rw = get_relative_word(k - term_offset)
                                        if rw and term_clean[k] ~= utf8_to_lower(rw:gsub("[%p%s]", "")) then
                                            sequence_match = false
                                            break
                                        end
                                    end
                                end
                            end

                            -- Phase 2: Context Match
                            if sequence_match and Options.anki_context_strict and not Options.anki_global_highlight then
                                local has_neighbor = false
                                -- Check word immediately before on screen
                                local prev_w = get_relative_word(-1)
                                if prev_w then
                                    local pw_clean = utf8_to_lower(prev_w:gsub("[%p%s]", ""))
                                    if pw_clean ~= "" then
                                        if ctx_lower:find(pw_clean, 1, true) or term_lower:find(pw_clean, 1, true) then
                                            has_neighbor = true
                                        end
                                    end
                                end
                                -- Check word immediately after on screen
                                if not has_neighbor then
                                    local next_w = get_relative_word(1)
                                    if next_w then
                                        local nw_clean = utf8_to_lower(next_w:gsub("[%p%s]", ""))
                                        if nw_clean ~= "" then
                                            if ctx_lower:find(nw_clean, 1, true) or term_lower:find(nw_clean, 1, true) then
                                                has_neighbor = true
                                            end
                                        end
                                    end
                                end
                                if not has_neighbor and #words > 1 then
                                    sequence_match = false
                                end
                            end

                            if sequence_match then
                                match_found = true
                                if #term_words > 1 then has_phrase = true end
                                break -- Out of offsets for this term
                            end
                        end
                    end
                end
            end
            if match_found then
                stack = stack + 1
                matched_terms[term_key] = true
                if stack >= 3 then break end
            end
        end
    end
    return stack, has_phrase
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



local function extract_anki_context(full_line, selected_term)
    if not full_line or full_line == "" then return "" end
    
    -- 1. Try to find the sentence boundary within the provided context lines
    local term_lower = selected_term:lower()
    local full_lower = full_line:lower()
    local start_pos, end_pos = full_lower:find(term_lower, 1, true)
    
    local sentence = full_line
    if start_pos then
        -- Search backwards for punctuation
        local pre = full_line:sub(1, start_pos - 1)
        local sent_start = 1
        -- Look for space followed by . ! ? in reversed string (meaning . ! ? followed by space in original)
        local b_idx = pre:reverse():find("%s+[.!?]")
        if b_idx then
            sent_start = start_pos - b_idx + 1
        end
        
        -- Search forwards for punctuation
        local post = full_line:sub(start_pos)
        local sent_end = #full_line
        -- Look for . ! ? 
        local f_idx = post:find("[.!?]")
        if f_idx then
            sent_end = start_pos + f_idx - 1
        end
        
        sentence = full_line:sub(sent_start, sent_end):match("^[%s.!?]*(.-)%s*$")
    end

    -- 2. Check word count of the extracted sentence
    local words = build_word_list(sentence)
    if #words <= Options.anki_context_max_words then return sentence end
    
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
    local half_max = math.floor(Options.anki_context_max_words / 2)
    local context_start = math.max(1, target_idx - half_max)
    local context_end = math.min(#words, last_idx + half_max)
    
    local context_words = {}
    for i = context_start, context_end do table.insert(context_words, words[i]) end
    
    return table.concat(context_words, " "):match("^%s*(.-)%s*$")
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

local function load_anki_tsv(force)
    local tsv_path = get_tsv_path()
    if not tsv_path then return end
    
    if FSM.ANKI_DB_PATH ~= tsv_path then
        FSM.ANKI_DB_PATH = tsv_path
        FSM.ANKI_HIGHLIGHTS = {}
    elseif not force then
        if next(FSM.ANKI_HIGHLIGHTS) ~= nil then return end
    end

    local f = io.open(tsv_path, "r")
    if not f then return end

    local new_highlights = {}

    local line_count = 0
    for line in f:lines() do
        line_count = line_count + 1
        if line_count > 1 then
            local fields = {}
            for field in (line .. "\t"):gmatch("([^\t]*)\t") do
                table.insert(fields, field)
            end
            if #fields >= 2 then
                local term = fields[1]
                local context = fields[2]
                local time_val = tonumber(fields[3]) or 0
                table.insert(new_highlights, { term = term, context = context, time = time_val })
            end
        end
    end
    f:close()
    
    FSM.ANKI_HIGHLIGHTS = new_highlights
end

local function save_anki_tsv_row(term, context, time_pos)
    local tsv_path = get_tsv_path()
    if not tsv_path then return end

    local f_check = io.open(tsv_path, "r")
    local exists = false
    if f_check then exists = true f_check:close() end

    local f = io.open(tsv_path, "a")
    if not f then return end

    if not exists then
        f:write(Options.anki_tsv_headers .. "	Time\n")
    end

    f:write(string.format("%s\t%s\t%.3f\n", term, context, time_pos))
    f:close()

    table.insert(FSM.ANKI_HIGHLIGHTS, { term = term, context = context, time = time_pos })
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

    -- Flush stale drum subs when track path changed or track was disabled
    if Tracks.pri.path ~= old_pri_path then Tracks.pri.subs = {} end
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
            mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
            mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
            mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
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
    local start_idx = math.max(1, center_idx - Options.drum_context_lines)
    local end_idx = math.min(#subs, center_idx + Options.drum_context_lines)
    local is_top = (y_pos_percent < 50)
    local y_pixel = y_pos_percent * 1080 / 100
    
    local function format_sub(sub_idx, is_active, t_pos)
        local text = subs[sub_idx] and subs[sub_idx].text or ""
        if text == "" then return "" end
        local base_color = is_active and Options.drum_active_color or Options.drum_context_color
        local opacity = is_active and Options.drum_active_opacity or Options.drum_context_opacity
        local bold_state = (is_active and Options.drum_active_bold or Options.drum_context_bold) and "1" or "0"
        local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
        
        local words = build_word_list(text)
        local formatted_parts = {}
        for i, w in ipairs(words) do
            local stack, is_phrase = calculate_highlight_stack(subs, sub_idx, i, t_pos)
            local h_color = base_color
            if stack == 1 then h_color = Options.anki_highlight_depth_1
            elseif stack == 2 then h_color = Options.anki_highlight_depth_2
            elseif stack >= 3 then h_color = Options.anki_highlight_depth_3 end

            if h_color ~= base_color then
                table.insert(formatted_parts, format_highlighted_word(w, h_color, base_color, is_phrase, bold_state, true))
            else
                table.insert(formatted_parts, w)
            end
        end
        local result_text = table.concat(formatted_parts, " ")

        return string.format("{\\1a&H%s&}{\\b%s}{\\1c&H%s&}{\\fs%d}%s", 
            opacity, bold_state, base_color, size, result_text)
    end

    local prev_text = ""
    for i = start_idx, center_idx - 1 do
        local sub = subs[i]
        prev_text = prev_text .. (prev_text == "" and "" or "\\N") .. format_sub(i, false, sub.start_time)
    end
    
    local active_text = ""
    if center_idx > 0 and center_idx <= #subs then
        local sub = subs[center_idx]
        local is_active = (time_pos >= sub.start_time and time_pos <= sub.end_time)
        active_text = format_sub(center_idx, is_active, sub.start_time)
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

    if is_top then
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s\n", y_pixel, font_size, all_text)
    else
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s\n", y_pixel, font_size, all_text)
    end

    return ass
end


-- Unified layout engine: wraps subtitle words into visual lines
local function dw_build_layout(subs, view_center)
    local win_lines = Options.dw_lines_visible
    local half_win = math.floor(win_lines / 2)
    view_center = math.max(1, math.min(#subs, view_center))
    local start_idx = math.max(1, view_center - half_win)
    local end_idx = math.min(#subs, start_idx + win_lines - 1)

    local vline_h = Options.dw_font_size * Options.dw_vline_h_mul
    local sub_gap = Options.dw_font_size * Options.dw_sub_gap_mul
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
    ass = ass .. string.format("{\\an5}{\\bord0}{\\shad0}{\\1a&H%s&}{\\3a&HFF&}{\\4a&HFF&}{\\1c&H%s&}{\\p1}m 0 0 l 1920 0 1920 1080 0 1080{\\p0}\n", bg_alpha, bg_color)
    
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
                    local sub_t = subs[i]
                    local stack, is_phrase = calculate_highlight_stack(subs, i, j, sub_t.start_time)
                    local h_color = color
                    if stack == 1 then h_color = Options.anki_highlight_depth_1
                    elseif stack == 2 then h_color = Options.anki_highlight_depth_2
                    elseif stack >= 3 then h_color = Options.anki_highlight_depth_3 end

                    if h_color ~= color then
                        table.insert(formatted_words, format_highlighted_word(w, h_color, color, is_phrase, "0", false))
                    else
                        table.insert(formatted_words, w)
                    end
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
    ass = ass .. string.format("{\\pos(960, 540)}{\\an5}{\\bord0}{\\shad0}{\\blur0}{\\1a&H00&}{\\3a&HFF&}{\\4a&HFF&}{\\q2}{\\fs%d}%s", 
        Options.dw_font_size, block_text)
    
    return ass
end

local function draw_dw_tooltip(subs, target_line_idx, osd_y)
    if target_line_idx == -1 or not Tracks.sec.subs or #Tracks.sec.subs == 0 then return "" end
    
    local primary_sub = subs[target_line_idx]
    if not primary_sub then return "" end
    
    local midpoint = (primary_sub.start_time + primary_sub.end_time) / 2
    local center_idx = get_center_index(Tracks.sec.subs, midpoint)
    if center_idx == -1 then return "" end
    
    local start_idx = math.max(1, center_idx - Options.dw_tooltip_context_lines)
    local end_idx = math.min(#Tracks.sec.subs, center_idx + Options.dw_tooltip_context_lines)
    
    local lines = {}
    for i = start_idx, end_idx do
        table.insert(lines, Tracks.sec.subs[i].raw_text)
    end
    local text = table.concat(lines, "\\N")
    
    local fs = Options.dw_tooltip_font_size
    local bg_alpha = Options.dw_tooltip_bg_opacity
    local bg_color = Options.dw_tooltip_bg_color
    local text_color = Options.dw_tooltip_text_color
    local text_alpha = Options.dw_tooltip_text_opacity or "00"
    local bold = Options.dw_tooltip_bold and "1" or "0"
    local bord = Options.dw_tooltip_border_size or 1.5
    local shad = Options.dw_tooltip_shadow_offset or 1.0

    local ass = string.format("{\\pos(1800, %d)}{\\an6}{\\fs%d}{\\b%s}{\\bord%g}{\\shad%g}{\\1c&H%s&}{\\1a&H%s&}{\\3c&H%s&}{\\4a&H%s&}{\\q1}%s",
        osd_y, fs, bold, bord, shad, text_color, text_alpha, bg_color, bg_alpha, text)
        
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

local function cmd_dw_tooltip_pin(tbl)
    if FSM.DRUM_WINDOW == "OFF" then return end
    
    if tbl.event == "down" then
        FSM.DW_TOOLTIP_HOLDING = true
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end
        
        local osd_x, osd_y = dw_get_mouse_osd()
        local line_idx, _ = dw_hit_test(osd_x, osd_y)
        
        if line_idx then
            FSM.DW_TOOLTIP_LOCKED_LINE = -1
            FSM.DW_TOOLTIP_LINE = line_idx
            local ass = draw_dw_tooltip(subs, line_idx, osd_y)
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
        FSM.DW_TOOLTIP_LINE = -1
        dw_tooltip_osd.data = ""
        dw_tooltip_osd:update()
    end
end

local function dw_tooltip_mouse_update()
    if FSM.DRUM_WINDOW == "OFF" then return end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    
    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, _ = dw_hit_test(osd_x, osd_y)
    
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
        if line_idx then
            if FSM.DW_TOOLTIP_LINE ~= line_idx then
                FSM.DW_TOOLTIP_LINE = line_idx
                dw_tooltip_osd.data = draw_dw_tooltip(subs, line_idx, osd_y)
                dw_tooltip_osd:update()
            end
        else
            if FSM.DW_TOOLTIP_LINE ~= -1 then
                FSM.DW_TOOLTIP_LINE = -1
                dw_tooltip_osd.data = ""
                dw_tooltip_osd:update()
            end
        end
    else
        -- CLICK mode or Selection Protected: check if we left the pinned line
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
        local term = ""
        local context_line = ""
        local time_pos = 0

        if al ~= -1 and aw ~= -1 and cl ~= -1 and cw ~= -1 then
            local p1_l, p1_w, p2_l, p2_w
            if al < cl or (al == cl and aw <= cw) then
                p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
            else
                p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
            end
            
            if not subs[p1_l] or not subs[p2_l] then return end

            local parts = {}
            for i = p1_l, p2_l do
                local text = (subs[i].text:gsub("\n", " "))
                local words = build_word_list(text)
                local s_w = (i == p1_l) and p1_w or 1
                local e_w = (i == p2_l) and p2_w or #words
                for j = s_w, e_w do 
                    if words[j] then table.insert(parts, words[j]) end
                end
            end
            term = table.concat(parts, " ")
            
            local ctx_parts = {}
            for k = math.max(1, p1_l - Options.anki_context_lines), math.min(#subs, p2_l + Options.anki_context_lines) do
                if subs[k] then table.insert(ctx_parts, (subs[k].text:gsub("\n", " "))) end
            end
            context_line = table.concat(ctx_parts, " ")
            time_pos = subs[p1_l].start_time
        elseif cl ~= -1 and subs[cl] then
            local sub = subs[cl]
            local ctx_parts = {}
            for k = math.max(1, cl - Options.anki_context_lines), math.min(#subs, cl + Options.anki_context_lines) do
                if subs[k] then table.insert(ctx_parts, (subs[k].text:gsub("\n", " "))) end
            end
            context_line = table.concat(ctx_parts, " ")
            time_pos = sub.start_time
            if cw ~= -1 then
                local line_words = build_word_list(sub.text:gsub("\n", " "))
                term = line_words[cw] or (sub.text:gsub("\n", " "))
            else
                term = sub.text:gsub("\n", " ")
            end
        end

        if term and term ~= "" then
            term = term:gsub("{[^}]+}", "")
            -- Clean capture: Remove leading/trailing punctuation and spaces
            local pre = term:match("^[%p%s]*")
            local suf = term:match("[%p%s]*$")
            if #pre < #term then
                term = term:sub(#pre + 1, #term - #suf)
            end
            
            context_line = context_line:gsub("{[^}]+}", "")
            local extracted_context = extract_anki_context(context_line, term)
            save_anki_tsv_row(term, extracted_context, time_pos)
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


local function make_mouse_handler(is_shift, on_up_callback)
    return function(tbl)
        if tbl.event == "down" then
            FSM.DW_FOLLOW_PLAYER = false

            -- Dismiss tooltip on click and lock suppression for the current focus
            local osd_x, osd_y = dw_get_mouse_osd()
            local line_idx, word_idx = dw_hit_test(osd_x, osd_y)
            
            FSM.DW_TOOLTIP_LOCKED_LINE = line_idx or -1
            if FSM.DW_TOOLTIP_LINE ~= -1 then
                FSM.DW_TOOLTIP_LINE = -1
                dw_tooltip_osd.data = ""
                dw_tooltip_osd:update()
            end

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
                elseif on_up_callback and is_inside_dw_selection(line_idx, word_idx) then
                    -- Preserve existing selection for 'SCM' commit (Middle-click committed existing range)
                else
                    -- Normal click: set both anchor and cursor (starts new selection)
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
                
                -- Force immediate update to show Red selection highlight on down
                drum_osd:update()
                if dw_osd then dw_osd:update() end
            end
        elseif tbl.event == "up" then
            FSM.DW_MOUSE_DRAGGING = false
            
            -- Lock suppression to the line where the interaction ended
            local osd_x, osd_y = dw_get_mouse_osd()
            local line_idx, _ = dw_hit_test(osd_x, osd_y)
            FSM.DW_TOOLTIP_LOCKED_LINE = line_idx or -1

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
            if on_up_callback then on_up_callback(tbl) end
        end
    end
end

local cmd_dw_mouse_select = make_mouse_handler(false)
local cmd_dw_mouse_select_shift = make_mouse_handler(true)
local cmd_dw_export_anki = make_mouse_handler(false, dw_anki_export_selection)

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
    
    dw_tooltip_mouse_update()
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


local function cmd_dw_scroll(dir)
    FSM.DW_FOLLOW_PLAYER = false
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    FSM.DW_VIEW_CENTER = math.max(1, math.min(#subs, FSM.DW_VIEW_CENTER + dir))
    FSM.DW_CURSOR_WORD = -1
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
            FSM.DW_FOLLOW_PLAYER = true
            FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
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
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_CURSOR_WORD = -1
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
    local keys = {
        {key = "LEFT", name = "dw-word-left", fn = function() cmd_dw_word_move(-1, false) end},
        {key = "RIGHT", name = "dw-word-right", fn = function() cmd_dw_word_move(1, false) end},
        {key = "UP", name = "dw-line-up", fn = function() cmd_dw_line_move(-1, false) end},
        {key = "DOWN", name = "dw-line-down", fn = function() cmd_dw_line_move(1, false) end},
        {key = "Shift+UP", name = "dw-line-up-shift", fn = function() cmd_dw_line_move(-1, true) end},
        {key = "Shift+DOWN", name = "dw-line-down-shift", fn = function() cmd_dw_line_move(1, true) end},
        {key = "a", name = "dw-seek-back", fn = function(t) cmd_seek_with_repeat(-1, t) end, complex = true},
        {key = "d", name = "dw-seek-fwd", fn = function(t) cmd_seek_with_repeat(1, t) end, complex = true},
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
        -- Mouse selection & Suppression
        {key = "MBTN_LEFT", name = "dw-mouse-select", fn = cmd_dw_mouse_select, complex = true},
        {key = "MBTN_MID", name = "dw-anki-export", fn = cmd_dw_export_anki, complex = true},
        {key = "Shift+MBTN_LEFT", name = "dw-mouse-select-shift", fn = cmd_dw_mouse_select_shift, complex = true},
        {key = "MBTN_LEFT_DBL", name = "dw-mouse-dblclick", fn = cmd_dw_double_click},
        -- Tooltip Bindings
        {key = Options.dw_tooltip_pin_key, name = "dw-tooltip-pin", fn = cmd_dw_tooltip_pin, complex = true},
        {key = Options.dw_tooltip_hover_key, name = "dw-tooltip-hover", fn = cmd_toggle_dw_tooltip_hover},
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
        {key = Options.dw_tooltip_hover_key_ru, name = "dw-tooltip-hover-ru", fn = cmd_toggle_dw_tooltip_hover},
        
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
        display_query = "{\\1a&HAA&}Search...{\\1a&H00&}|"
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
                local selected_line = FSM.SEARCH_RESULTS[FSM.SEARCH_SEL_IDX].idx
                local sub = Tracks.pri.subs[selected_line]
                
                if sub.start_time then
                    mp.commandv("seek", sub.start_time, "absolute+exact")
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
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Drum Window: No subtitles loaded")
        return
    end
    if not Tracks.pri.path then
        show_osd("Drum Window: Requires external subtitle files")
        return
    end

    if FSM.DRUM_WINDOW == "OFF" then
        FSM.DRUM_WINDOW = "DOCKED"
        manage_ui_border_override(true)
        
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
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_FOLLOW_PLAYER = true
        
        if not FSM.SEARCH_MODE then
            manage_dw_bindings(true)
        end
        -- show_osd("Drum Window: OPEN")
    else
        FSM.DRUM_WINDOW = "OFF"
        manage_ui_border_override(false)
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

        -- show_osd("Drum Window: CLOSED")
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

mp.observe_property("sid", "number", update_media_state)
mp.observe_property("secondary-sid", "number", update_media_state)
mp.observe_property("track-list", "native", function()
    update_media_state()
    if Options.font_scaling_enabled then
        update_font_scale()
    end
end)
mp.observe_property("osd-dimensions", "native", function()
    if Options.font_scaling_enabled then
        update_font_scale()
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
mp.add_key_binding(nil, "lls-seek_prev", function(t) cmd_seek_with_repeat(-1, t) end, {complex = true})
mp.add_key_binding(nil, "lls-seek_next", function(t) cmd_seek_with_repeat(1, t) end, {complex = true})
mp.add_key_binding(nil, "toggle-anki-global", cmd_toggle_anki_global)

if Options.anki_sync_period > 0 then
    mp.add_periodic_timer(Options.anki_sync_period, function()
        pcall(function()
            load_anki_tsv(true)
            drum_osd:update()
            if dw_osd then dw_osd:update() end
        end)
    end)
end
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
