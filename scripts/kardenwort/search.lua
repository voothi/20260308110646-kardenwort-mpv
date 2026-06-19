-- ===============================================================================
-- search.lua — Search HUD feature for kardenwort
-- Deepest DI phase: the module receives main.lua-local helpers
-- (wrap_tokens, dw_get_mouse_osd, manage_ui_border_override,
--  manage_dw_bindings, update_interactive_bindings, render_search) via a
-- helpers table read at call time, because those are defined after init().
-- Carve-out (stay in main.lua): apply_border_override_state,
-- manage_ui_border_override, trigger_volume_suspension.
-- ===============================================================================

local mp = require 'mp'
local utils = require 'mp.utils'
local text_utils = require 'text_utils'
local subtitle_parser = require 'subtitle_parser'

local M = {}

local FSM, Options, Tracks, Diagnostic
local _helpers

function M.init(fsm, opts, tracks, diagnostic, helpers)
    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diagnostic
    _helpers = helpers or {}
end

-- Helpers read at call time (defined later in main.lua than init()).
-- Referenced directly via _helpers table — no wrapper call frames needed.

local function utf8_to_table(s) return text_utils.utf8_to_table(s) end
local function normalize_inline_break_markers(s) return text_utils.normalize_inline_break_markers(s) end
local function build_word_list_internal(...) return text_utils.build_word_list_internal(...) end
local function calculate_ass_alpha(v) return text_utils.calculate_ass_alpha(v) end

-- --- search-only scoring helpers (moved from main.lua) ---------------------

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
    local str_lower = text_utils.utf8_to_lower(str)
    local query_lower = text_utils.utf8_to_lower(query)

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

local function get_word_boundary(q_table, pos, direction)
    -- direction: -1 (left), 1 (right)
    if #q_table == 0 then return 0 end

    local new_pos = pos

    if direction == -1 then
        -- Skip spaces to the left
        while new_pos > 0 and not text_utils.is_word_char(q_table[new_pos]) do
            new_pos = new_pos - 1
        end
        -- Skip word chars to the left
        while new_pos > 0 and text_utils.is_word_char(q_table[new_pos]) do
            new_pos = new_pos - 1
        end
    else
        -- Skip spaces to the right
        while new_pos < #q_table and not text_utils.is_word_char(q_table[new_pos + 1]) do
            new_pos = new_pos + 1
        end
        -- Skip word chars to the right
        while new_pos < #q_table and text_utils.is_word_char(q_table[new_pos + 1]) do
            new_pos = new_pos + 1
        end
    end

    return new_pos
end

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

-- --- search UI ---------------------------------------------------------

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

    local box_w = 1200
    local box_x = 960 - (box_w / 2)
    local box_y = 50

    local bg_color = Options.search_bg_color or "181818"
    local border_color = "666666"
    local text_color = Options.search_text_color or "FFFFFF"
    local bord = 0
    local shad = Options.search_shadow_offset or 0.0

    local opacity_hex = calculate_ass_alpha(Options.search_bg_opacity or "60")
    local text_bgbox_neutral = (FSM.osd_border_style == "background-box" and not FSM.SEARCH_BORDER_OVERRIDE)
        and "{\\3a&HFF&}{\\4a&HFF&}" or ""

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

    local stripped_query = display_query:gsub("{[^}]+}", "")
    local query_char_tokens = {}
    for c in stripped_query:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(query_char_tokens, {text = c})
    end

    local query_vlines = _helpers.wrap_tokens(query_char_tokens, box_w - padding_x * 2, font_size, font_name, true)
    local query_line_count = math.max(1, #query_vlines)

    local input_box_h = query_line_count * line_height + padding_y * 2

    local ass = ""
    ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
        box_x, box_y, bord, border_color, bg_color, opacity_hex, opacity_hex, opacity_hex, bg_color, box_w, box_w, input_box_h, input_box_h)

    ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad%g}{\\4a&H%s&}{\\fs%d}{\\c&H%s&}%s %s\n",
        font_name, box_x + padding_x, box_y + padding_y, shad, opacity_hex, font_size, "FFFFFF", text_bgbox_neutral, display_query)

    if #FSM.SEARCH_RESULTS > 0 then
        local max_results_display = 8
        local display_count = math.min(#FSM.SEARCH_RESULTS, max_results_display)
        local results_y = box_y + input_box_h + 5

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
            local sub_text = normalize_inline_break_markers(Tracks.pri.subs[result_data.idx].text):gsub("\n", " ")
            local raw_t_table = utf8_to_table(sub_text)

            if #raw_t_table > 120 then
                local new_t = {}
                for i = 1, 120 do table.insert(new_t, raw_t_table[i]) end
                sub_text = table.concat(new_t) .. "..."
            end

            local res_tokens = build_word_list_internal(sub_text, true)
            local res_vlines = _helpers.wrap_tokens(res_tokens, box_w - padding_x * 2, r_font_size, font_name, true)

            table.insert(results_layout, {
                data = result_data,
                vlines = res_vlines,
                idx = result_idx,
                tokens = res_tokens
            })
            total_results_vlines = total_results_vlines + #res_vlines
        end

        local results_h = total_results_vlines * r_line_height + padding_y * 2

        ass = ass .. string.format("{\\pos(%d,%d)}{\\an7}{\\bord%g}{\\3c&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\c&H%s&}{\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}\n",
            box_x, results_y, bord, border_color, bg_color, opacity_hex, opacity_hex, opacity_hex, bg_color, box_w, box_w, results_h, results_h)

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

                table.insert(FSM.SEARCH_HIT_ZONES, {
                    result_idx = result_idx,
                    y_top = current_y,
                    y_bottom = current_y + r_line_height
                })

                ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&H%s&}{\\fs%d}{\\c&H%s&}%s %s%s%s\n",
                    font_name, box_x + padding_x, current_y, opacity_hex, r_font_size, base_color, text_bgbox_neutral, sel_bold, display_text, sel_bold_end)

                current_y = current_y + r_line_height
            end
        end
    elseif FSM.SEARCH_QUERY ~= "" then
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
        ass = ass .. string.format("{\\fn%s}{\\pos(%d,%d)}{\\an7}{\\bord0}{\\shad0}{\\4a&H%s&}{\\fs%d}{\\c&H%s&}%s No results found.\n",
            font_name, box_x + padding_x, results_y + padding_y, opacity_hex, r_font_size, "999999", text_bgbox_neutral)
    end

    return ass
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
    _helpers.render_search()
end

-- --- search input bindings ----------------------------------------------

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

        FSM.SEARCH_BORDER_OVERRIDE = (FSM.DRUM_WINDOW ~= "OFF")
        if FSM.SEARCH_BORDER_OVERRIDE then
            _helpers.manage_ui_border_override(true)
        end

        if Tracks.pri.path and #Tracks.pri.subs == 0 then
            Tracks.pri.subs = subtitle_parser.load_sub(Tracks.pri.path, Tracks.pri.is_ass)
        end

        if FSM.DRUM_WINDOW == "DOCKED" then
            _helpers.manage_dw_bindings(false)
        end

        FSM.SEARCH_CHAR_BINDINGS = {}
        for ch in utf8_iter_chars(SEARCH_INPUT_CHARS) do
            local key_name = (ch == " ") and "SPACE" or ch
            local binding_name = search_binding_name_for_char(ch)
            FSM.SEARCH_CHAR_BINDINGS[binding_name] = true

            mp.add_forced_key_binding(key_name, binding_name, function()
                local q_table = utf8_to_table(FSM.SEARCH_QUERY)

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
                _helpers.render_search()
            end, "repeatable")
        end
        for _, ch in ipairs(SEARCH_GERMAN_CHARS) do
            local binding_name = search_binding_name_for_char(ch)
            if not FSM.SEARCH_CHAR_BINDINGS[binding_name] then
                Diagnostic.error("Search binding registry missing German key binding: " .. ch)
            end
        end

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
                _helpers.render_search()
            elseif FSM.SEARCH_CURSOR > 0 then
                table.remove(q_table, FSM.SEARCH_CURSOR)
                FSM.SEARCH_QUERY = table.concat(q_table)
                FSM.SEARCH_CURSOR = FSM.SEARCH_CURSOR - 1

                update_search_results()
                _helpers.render_search()
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
                _helpers.render_search()
            elseif FSM.SEARCH_CURSOR < #q_table then
                table.remove(q_table, FSM.SEARCH_CURSOR + 1)
                FSM.SEARCH_QUERY = table.concat(q_table)

                update_search_results()
                _helpers.render_search()
            end
        end, "repeatable")

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
            _helpers.render_search()
        end)
        bind(Options.search_key_end, "end", function()
            FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
            FSM.SEARCH_ANCHOR = -1
            _helpers.render_search()
        end)

        mp.add_forced_key_binding("UP", "search-up", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.max(1, FSM.SEARCH_SEL_IDX - 1)
                _helpers.render_search()
            end
        end, "repeatable")

        mp.add_forced_key_binding("DOWN", "search-down", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.min(#FSM.SEARCH_RESULTS, FSM.SEARCH_SEL_IDX + 1)
                _helpers.render_search()
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

                FSM.DW_CURSOR_LINE = selected_line
                FSM.DW_CURSOR_WORD = -1
                FSM.DW_CURSOR_X = nil
                FSM.DW_VIEW_CENTER = selected_line
                FSM.DW_FOLLOW_PLAYER = true
                FSM.DW_ANCHOR_LINE = -1
                FSM.DW_ANCHOR_WORD = -1

                M.cmd_toggle_search()
            end
        end)

        bind(Options.search_key_esc, "esc", function()
            M.cmd_toggle_search()
        end)

        mp.add_forced_key_binding("WHEEL_UP", "search-wheel-up", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.max(1, FSM.SEARCH_SEL_IDX - 1)
                _helpers.render_search()
            end
        end)
        mp.add_forced_key_binding("WHEEL_DOWN", "search-wheel-down", function()
            if #FSM.SEARCH_RESULTS > 0 then
                FSM.SEARCH_SEL_IDX = math.min(#FSM.SEARCH_RESULTS, FSM.SEARCH_SEL_IDX + 1)
                _helpers.render_search()
            end
        end)

        local function paste_from_clipboard()
            local clipboard_txt = get_clipboard()
            if clipboard_txt and clipboard_txt ~= "" then
                local txt = clipboard_txt:gsub("\r", ""):gsub("\n", " ")
                if txt ~= "" then
                    local q_table = utf8_to_table(FSM.SEARCH_QUERY)

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
                    _helpers.render_search()
                end
            end
        end
        bind(Options.search_key_paste, "paste", paste_from_clipboard, "repeatable")

        local function select_all()
            FSM.SEARCH_ANCHOR = 0
            FSM.SEARCH_CURSOR = #utf8_to_table(FSM.SEARCH_QUERY)
            _helpers.render_search()
        end
        bind(Options.search_key_select_all, "select-all", select_all)

        local function delete_word_before_cursor()
            if FSM.SEARCH_QUERY == "" or FSM.SEARCH_CURSOR == 0 then return end

            local q_table = utf8_to_table(FSM.SEARCH_QUERY)
            local target_pos = get_word_boundary(q_table, FSM.SEARCH_CURSOR, -1)

            if FSM.SEARCH_ANCHOR ~= -1 and FSM.SEARCH_ANCHOR ~= FSM.SEARCH_CURSOR then
                local s_start = math.min(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                local s_end = math.max(FSM.SEARCH_ANCHOR, FSM.SEARCH_CURSOR)
                for i = s_end, s_start + 1, -1 do
                    table.remove(q_table, i)
                end
                FSM.SEARCH_CURSOR = s_start
                FSM.SEARCH_ANCHOR = -1
            else
                for i = FSM.SEARCH_CURSOR, target_pos + 1, -1 do
                    table.remove(q_table, i)
                end
                FSM.SEARCH_CURSOR = target_pos
            end

            FSM.SEARCH_QUERY = table.concat(q_table)
            update_search_results()
            _helpers.render_search()
        end
        bind(Options.search_key_delete_word, "delete-word", delete_word_before_cursor, "repeatable")

        local function search_mouse_click(tbl)
            if tbl.event == "down" then
                if FSM.DW_MOUSE_LOCK_UNTIL and mp.get_time() < FSM.DW_MOUSE_LOCK_UNTIL then return end

                if #FSM.SEARCH_RESULTS == 0 or not FSM.SEARCH_HIT_ZONES then return end

                local osd_x, osd_y = _helpers.dw_get_mouse_osd()

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

                    M.cmd_toggle_search()
                end
            end
        end
        bind(Options.search_key_click, "mouse-click", search_mouse_click, {complex = true})

        _helpers.render_search()
    else
        FSM.SEARCH_MODE = false
        if FSM.SEARCH_BORDER_OVERRIDE then
            _helpers.manage_ui_border_override(false)
            FSM.SEARCH_BORDER_OVERRIDE = false
        end

        for name, _ in pairs(FSM.SEARCH_CHAR_BINDINGS or {}) do
            mp.remove_key_binding(name)
        end
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

        _helpers.render_search()

        _helpers.update_interactive_bindings()
    end
end

function M.cmd_toggle_search()
    if not FSM.SEARCH_MODE then
        if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
            _helpers.show_osd("X")
            return
        end
        if FSM.MEDIA_STATE == "NO_SUBS" then
            _helpers.show_osd("Search: No subtitles loaded")
            return
        end
        if not Tracks.pri.path and not Tracks.sec.path then
            _helpers.show_osd("Search: Requires external subtitle files")
            return
        end
        manage_search_bindings(true)
    else
        manage_search_bindings(false)
    end
end

-- --- module exports --------------------------------------------------------
M.update_search_results = update_search_results
M.draw_search_ui = draw_search_ui
M.move_search_cursor = move_search_cursor
M.manage_search_bindings = manage_search_bindings
M.find_fuzzy_indices = find_fuzzy_indices
M.calculate_match_score = calculate_match_score
M.get_word_boundary = get_word_boundary
M.get_clipboard = get_clipboard
M.utf8_iter_chars = utf8_iter_chars

return M
