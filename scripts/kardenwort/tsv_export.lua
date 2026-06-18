-- =========================================================================
-- tsv_export.lua — TSV/Anki export & copy pipeline for kardenwort
-- Extracted from main.lua (Phase 6 of refactor 20260618120822).
-- Contains the text-extraction mechanisms that feed TSV saving
-- (prepare_export_text, extract_anki_context, clean_anki_term), TSV I/O
-- (load_anki_tsv, save_anki_tsv_row), and Anki field-mapping
-- (resolve_anki_field, load_anki_mapping_ini). ~22 functions, ~600 lines.
-- Reads FSM/Options/Tracks/Diagnostic at call time via injected references.
-- Requires text_utils for pure text helpers (no circular dependency).
-- =========================================================================

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

-- safe_read_file and flush_rendering_caches are read at call time from the
-- helpers table so main.lua can populate them after this init() runs (they
-- are defined later in main.lua than the init() call site).
local function safe_read_file(path)
    return _helpers.safe_read_file(path)
end

local function flush_rendering_caches()
    if _helpers.flush_rendering_caches then _helpers.flush_rendering_caches() end
end

local L_EPSILON = 0.0001

-- Module-local caches (moved from main.lua).
local ANKI_MAPPING_CACHE = nil
local SOURCE_URL_CACHE = nil
local SOURCE_URL_FILE_PATH = nil
local SOURCE_URL_FILE_MTIME = 0
local SOURCE_URL_FILE_SIZE = 0
local LAST_PATH_FOR_URL = nil

-- --- copy context ----------------------------------------------------------

local function get_copy_context_text(time_pos, line_idx)
    time_pos = time_pos or mp.get_property_number("time-pos") or 0
    local combined = {}

    local function trim(s) return s:match("^%s*(.-)%s*$") or "" end

    local function is_target(s)
        if not s then return false end
        local cyr = text_utils.has_cyrillic(s)
        if FSM.COPY_MODE == "A" then
            return not cyr
        else
            return cyr
        end
    end

    local function append(path, is_ass, explicit_idx, provided_subs)
        if not path and not provided_subs then return end
        local subs = provided_subs
        if not subs then
            if Tracks.pri.path == path and FSM.DRUM == "ON" and not is_ass then subs = Tracks.pri.subs
            elseif Tracks.sec.path == path and FSM.DRUM == "ON" and not is_ass then subs = Tracks.sec.subs
            else subs = subtitle_parser.load_sub(path, is_ass) end
        end

        if subs and #subs > 0 then
            local idx = explicit_idx or subtitle_parser.get_center_index(subs, time_pos)
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
    elseif FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0 then
        append(nil, false, nil, FSM.DW_TOOLTIP_SEC_SUBS)
    end

    return #combined > 0 and table.concat(combined, "\n") or nil
end

-- --- Anki mapping ----------------------------------------------------------

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
    str = text_utils.normalize_inline_break_markers(str)
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

local function clean_anki_term(term)
    if not term or term == "" then return "" end
    term = term:gsub("{[^}]+}", "")
    term = term:match("^%s*(.-)%s*$")
    return term or ""
end

-- --- export text builder ---------------------------------------------------

local function prepare_export_text(params, options)
    options = options or {}
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return "" end
    local target_subs = subs
    if options.copy_mode == "B" then
        if Tracks.sec.subs and #Tracks.sec.subs > 0 then
            target_subs = Tracks.sec.subs
        elseif FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0 then
            target_subs = FSM.DW_TOOLTIP_SEC_SUBS
        end
    end

    local parts = {}

    if params.type == "RANGE" then
        local p1_l, p1_w, p2_l, p2_w = params.p1_l, params.p1_w, params.p2_l, params.p2_w
        for i = p1_l, p2_l do
            local sub = target_subs[i]
            if sub then
                local raw_text = text_utils.normalize_inline_break_markers(sub.text):gsub("\n", " ")
                local tokens = text_utils.build_word_list_internal(raw_text, true)

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
            local sub = target_subs[m.line]
            if sub then
                local raw_text = text_utils.normalize_inline_break_markers(sub.text):gsub("\n", " ")
                local tokens = text_utils.build_word_list_internal(raw_text, true)
                local w_text = nil


                for _, t in ipairs(tokens) do
                    if text_utils.logical_cmp(t.logical_idx, m.word) then
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
                            local prev_sub_tokens = text_utils.get_sub_tokens(subs[last_m.line], true) or {}
                            local next_sub_tokens = text_utils.get_sub_tokens(subs[m.line], true) or {}
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
                                local last_line_tokens = text_utils.build_word_list_internal(text_utils.normalize_inline_break_markers(target_subs[last_m.line].text):gsub("\n", " "), true)
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
        local sub = target_subs[params.line]
        if sub then
            local raw_text = text_utils.normalize_inline_break_markers(sub.text):gsub("\n", " ")
            if params.word and params.word ~= -1 then
                local tokens = text_utils.build_word_list_internal(raw_text, true)
                for _, t in ipairs(tokens) do
                    if text_utils.logical_cmp(t.logical_idx, params.word) then
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
                local cyr = text_utils.has_cyrillic(ln)
                if (options.copy_mode == "A" and not cyr) or (options.copy_mode == "B" and cyr) then table.insert(valid, ln) end
            end
            if #valid == 0 then table.insert(valid, (options.copy_mode == "A") and lines[1] or lines[#lines]) end
            final_text = table.concat(valid, " ")
        end
    end

    return final_text or ""
end

-- --- SentenceSource context engine (extract_anki_context) ------------------

local function extract_anki_context(full_line, selected_term, max_words_override, pivot_pos, coord_map)
    if not full_line or full_line == "" then return "" end
    if not selected_term or selected_term == "" then return full_line end

    -- Helpers scoped here to avoid consuming module-level local slots (Lua 200-local limit).
    local function token_ending_at(s, i)
        local j = i
        while j >= 1 do
            local c = s:sub(j, j)
            if c == " " or c == "\0" or c == "\t" or c == "\n" then break end
            j = j - 1
        end
        return s:sub(j + 1, i)
    end
    local function is_terminator_char(c)
        local t = Options.anki_sentence_terminators
        if not t or t == "" then t = ".!?" end
        return t:find(c, 1, true) ~= nil
    end
    local function lookahead_after(s, pos)
        local j = pos + 1
        while j <= #s do
            local c = s:sub(j, j)
            if c ~= " " and c ~= "\t" and c ~= "\0" and c ~= "\n" then return c end
            j = j + 1
        end
        return ""
    end
    local function is_spaced_initialism_period_at(s, dot_pos)
        -- Detect abbreviations like "z. B." where the first period must not end a sentence.
        local prev = s:sub(dot_pos - 1, dot_pos - 1)
        if not prev:match("^%a$") then return false end
        local j = dot_pos + 1
        while j <= #s do
            local c = s:sub(j, j)
            if c ~= " " and c ~= "\t" and c ~= "\0" and c ~= "\n" then
                if c:match("^%a$") then
                    local k = j + 1
                    while k <= #s do
                        local c2 = s:sub(k, k)
                        if c2 ~= " " and c2 ~= "\t" and c2 ~= "\0" and c2 ~= "\n" then
                            return c2 == "."
                        end
                        k = k + 1
                    end
                end
                return false
            end
            j = j + 1
        end
        return false
    end

    -- 1. Try to find the occurrence closest to the pivot position (or center if not provided).
    -- This handles ambiguous common words (e.g. "die") when multiple context lines are present.
    -- If coord_map is provided (Gap 1 compliance), we prioritize logical grounding.
    local term_lower = selected_term:lower()
    local full_lower = full_line:lower()
    local center = pivot_pos or (#full_line / 2)
    local start_pos, end_pos = nil, nil
    local best_dist = math.huge
    local search_from = 1

    Diagnostic.debug(string.format("Search Pivot: %.1f | Term: '%s' | Text Len: %d", center, selected_term, #full_line))
    while true do
        local s, e = full_lower:find(term_lower, search_from, true)
        if not s then break end
        local dist = math.abs((s + e) / 2 - center)
        Diagnostic.debug(string.format("Candidate at %d-%d | Dist: %.1f", s, e, dist))
        if dist < best_dist then
            best_dist = dist
            start_pos, end_pos = s, e
        end
        search_from = math.max(search_from + 1, e + 1)
    end
    if start_pos then Diagnostic.debug(string.format("Selected match at index %d", start_pos)) end

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

    local pad_before = Options.anki_context_words_before or 0
    local pad_after = Options.anki_context_words_after or 0
    local padding_active = (pad_before > 0) or (pad_after > 0)

    local sentence = full_line
    local sent_start = 1
    local sent_end = #full_line
    local sentence_abs_start = 1   -- tracks where the cleaned sentence starts in full_line
    local has_real_boundary = false

    if start_pos then
        -- === Backward scan: find nearest real sentence terminator before start_pos ===
        -- Scans across \0 sentinels; skips abbreviations via is_abbrev.
        -- If no real terminator found, sent_start stays at 1 (full-block fallback).
        local b_term_pos = nil
        local i = start_pos - 1
        while i >= 1 do
            local c = full_line:sub(i, i)
            if is_terminator_char(c) then
                -- Look-ahead: char immediately after the terminator must be whitespace/NUL/end
                local after = full_line:sub(i + 1, i + 1)
                if after == "" or after == " " or after == "\t" or after == "\0" then
                    -- For "!" and "?" there is no abbreviation concern; always a real boundary.
                    -- For "." check whether the preceding token is an abbreviation. The
                    -- look-ahead character lets is_abbrev suppress the lowercase heuristic
                    -- when the period is clearly followed by a new sentence (uppercase).
                    if c ~= "." or (not text_utils.is_abbrev(token_ending_at(full_line, i), lookahead_after(full_line, i)) and not is_spaced_initialism_period_at(full_line, i)) then
                        b_term_pos = i
                        break
                    end
                end
            end
            i = i - 1
        end
        if b_term_pos then
            sent_start = b_term_pos + 1   -- sentence begins right after the terminator
            has_real_boundary = true
            Diagnostic.debug(string.format("Sent boundary (backward): terminator '%s' at %d, sent_start=%d",
                full_line:sub(b_term_pos, b_term_pos), b_term_pos, sent_start))
        else
            sent_start = 1
            Diagnostic.debug("Sent boundary (backward): no terminator found, fallback to block start")
        end

        -- === Forward scan: find nearest real sentence terminator after end_pos ===
        local f_term_pos = nil
        local k = end_pos + 1
        while k <= #full_line do
            local c = full_line:sub(k, k)
            if is_terminator_char(c) then
                local after = full_line:sub(k + 1, k + 1)
                if after == "" or after == " " or after == "\t" or after == "\0" then
                    if c ~= "." or (not text_utils.is_abbrev(token_ending_at(full_line, k), lookahead_after(full_line, k)) and not is_spaced_initialism_period_at(full_line, k)) then
                        f_term_pos = k
                        break
                    end
                end
            end
            k = k + 1
        end
        if f_term_pos then
            sent_end = f_term_pos   -- include the terminator character
            has_real_boundary = true
            Diagnostic.debug(string.format("Sent boundary (forward): terminator '%s' at %d, sent_end=%d",
                full_line:sub(f_term_pos, f_term_pos), f_term_pos, sent_end))
        else
            sent_end = #full_line
            Diagnostic.debug("Sent boundary (forward): no terminator found, fallback to block end")
        end

        local padding_allowed = padding_active and has_real_boundary
        if padding_allowed then
            -- Expand sentence-scoped byte bounds by logical words while keeping literal source slicing.
            local full_line_spaced = full_line:gsub("%z", " ")
            local tokens = text_utils.build_word_list_internal(full_line_spaced, true)
            local word_tokens = {}
            local curr_byte = 1
            for _, t in ipairs(tokens) do
                local start_byte = curr_byte
                local end_byte = curr_byte + #t.text - 1
                if t.is_word then
                    table.insert(word_tokens, {
                        start_byte = start_byte,
                        end_byte = end_byte,
                    })
                end
                curr_byte = end_byte + 1
            end

            local first_sent_word_idx, last_sent_word_idx = nil, nil
            for idx, wt in ipairs(word_tokens) do
                if wt.end_byte >= sent_start and wt.start_byte <= sent_end then
                    first_sent_word_idx = first_sent_word_idx or idx
                    last_sent_word_idx = idx
                end
            end

            if first_sent_word_idx and last_sent_word_idx then
                local final_first_word_idx = math.max(1, first_sent_word_idx - pad_before)
                local final_last_word_idx = math.min(#word_tokens, last_sent_word_idx + pad_after)
                if final_first_word_idx < first_sent_word_idx then
                    sent_start = word_tokens[final_first_word_idx].start_byte
                end
                if final_last_word_idx > last_sent_word_idx then
                    sent_end = word_tokens[final_last_word_idx].end_byte
                end
            end
        end

        local raw_sub = full_line:sub(sent_start, sent_end)
        -- Replace sentinels with spaces and trim
        sentence = raw_sub:gsub("%z", " "):match("^%s*(.-)%s*$") or ""

        -- Track where the cleaned sentence actually begins in full_line (for truncation offset math)
        local lead = raw_sub:match("^([%s%z]*)") or ""
        sentence_abs_start = sent_start + #lead
    end

    -- 2. Check word count of the extracted sentence.
    local words = text_utils.build_word_list(sentence)
    local limit = max_words_override or Options.anki_context_max_words

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

    local span = last_idx - first_idx + 1
    local padding_allowed = padding_active and has_real_boundary
    if padding_allowed then
        local words_needed = span + pad_before + pad_after
        if words_needed > limit then
            limit = words_needed
        end
    end
    if #words <= limit then return sentence end

    -- If the selection span itself is wider than the limit, the user picked words far apart.
    if span >= limit then
        local pad_left = Options.anki_context_span_pad or 3
        local pad_right = pad_left
        if padding_allowed then
            pad_left = math.max(pad_left, pad_before)
            pad_right = math.max(pad_right, pad_after)
        end
        local crop_start = math.max(1, first_idx - pad_left)
        local crop_end   = math.min(#words, last_idx + pad_right)
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
        context_end = last_idx or context_end
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

-- --- TSV path / I/O --------------------------------------------------------

local function get_tsv_path()
    if Options.anki_record_file and Options.anki_record_file ~= "" then return Options.anki_record_file end
    local path = mp.get_property("path")
    if not path then return nil end
    local base = path:match("(.+)%.[^%.]+$")
    if not base then base = path end
    return base .. ".tsv"
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
        -- Skip reload if fingerprint matches
        return
    end

    -- Load mapping config before opening file
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

    -- Read file with safety check
    local content = safe_read_file(tsv_path)
    if not content then
        FSM.ANKI_HIGHLIGHTS = {}
        -- Skip auto-creation if no subtitles loaded
        if FSM.MEDIA_STATE == "NO_SUBS" then
            Diagnostic.info("TSV auto-creation skipped: no subtitles loaded for current media")
            return
        end
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

    local row_id = 0
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
                        row_id = row_id + 1
                        local data = { term = t, context = c, time = time_val, index = idx_val }
                        data.__entry_key = table.concat({
                            tostring(t),
                            tostring(c),
                            string.format("%.6f", tonumber(time_val) or 0),
                            tostring(idx_val or ""),
                            tostring(row_id)
                        }, "|")
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
                                    local r_l = tonumber(l_off) or 0
                                    local r_w = tonumber(p_idx) or 0
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
    local term_words = text_utils.build_word_list(term)
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
    local exists = false
    local is_empty = true
    if f_check then
        exists = true
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

    local new_data = { term = term, context = context, time = time_pos, index = item_index }
    local next_row_id = #FSM.ANKI_HIGHLIGHTS + 1
    new_data.__entry_key = table.concat({
        tostring(term),
        tostring(context),
        string.format("%.6f", tonumber(time_pos) or 0),
        tostring(item_index or ""),
        tostring(next_row_id)
    }, "|")
    table.insert(FSM.ANKI_HIGHLIGHTS, new_data)
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

-- --- module exports --------------------------------------------------------
M.get_copy_context_text = get_copy_context_text
M.load_anki_mapping_ini = load_anki_mapping_ini
M.extract_subtitle_metadata = extract_subtitle_metadata
M.find_source_url = find_source_url
M.escape_tsv = escape_tsv
M.resolve_anki_field = resolve_anki_field
M.clean_anki_term = clean_anki_term
M.prepare_export_text = prepare_export_text
M.extract_anki_context = extract_anki_context
M.get_tsv_path = get_tsv_path
M.load_anki_tsv = load_anki_tsv
M.save_anki_tsv_row = save_anki_tsv_row

return M