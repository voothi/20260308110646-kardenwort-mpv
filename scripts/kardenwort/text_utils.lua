-- ===============================================================================
-- text_utils.lua — Pure text / tokenization helpers for kardenwort
-- Reads Options at call time via the injected `opts` reference (never copied).
-- ===============================================================================

local mp = require 'mp'

local M = {}

local _opts

function M.init(fsm, opts)
    assert(opts, "FATAL: opts dependency missing")
    _opts = opts
end

-- --- pure helpers (no singleton access) -----------------------------------

local function utf8_to_table(str)
    local t = {}
    for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(t, ch)
    end
    return t
end

local function utf8_truncate(str, max_chars)
    if not str or str == "" then return "" end
    local chars = utf8_to_table(str)
    if #chars <= max_chars then return str end
    local out = {}
    for i = 1, max_chars do
        out[#out + 1] = chars[i]
    end
    return table.concat(out, "") .. "..."
end

local function build_copy_preview(label, text, max_chars)
    return tostring(label or "DW") .. " Copied: " .. utf8_truncate(text or "", max_chars or 40)
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

local function is_abbrev(w, lookahead)
    if not w then return false end
    local l_word = w:lower()
    local abbrev_list = " " .. (_opts.anki_abbrev_list or ""):lower() .. " "
    if abbrev_list:find(" " .. l_word .. " ", 1, true) then return true end
    if _opts.anki_abbrev_smart then
        -- The 1-4 lowercase letter heuristic catches German shorts like ca./usw./vgl.,
        -- but also misfires on common 3-5 char English/German words at sentence end
        -- ("work.", "view.", "use.", "way."). Real sentence terminators are almost
        -- always followed by an uppercase letter; when the look-ahead is uppercase
        -- we suppress the heuristic so the explicit list stays authoritative.
        local heuristic_suppressed = lookahead and lookahead:match("^%u$") ~= nil
        if not heuristic_suppressed and w:match("^%l+%.$") and #w <= 5 then return true end
        if w:match("^%u%.$") then return true end
        if w:match("^%u%.%u%.$") then return true end
    end
    return false
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

local function normalize_inline_break_markers(text)
    if not text or text == "" then return text or "" end
    -- Normalize escaped ASS-style break markers that may appear in SRT/TXT content.
    -- Keep boundaries clean so downstream newline->space conversion does not create
    -- synthetic double spaces.
    local rules = {
        { pat = "\\+N", repl = "\n", tag = "\\N" },
        { pat = "\\+n", repl = "\n", tag = "\\n" },
        { pat = "\\+h", repl = " ", tag = "\\h" }
    }
    local tags_str = " " .. (_opts.unescape_tags or "") .. " "
    for _, rule in ipairs(rules) do
        if tags_str:find(" " .. rule.tag .. " ", 1, true) then
            text = text:gsub(rule.pat, rule.repl)
        end
    end
    text = text:gsub("[ \t]*\n[ \t]*", "\n")
    return text
end

local function get_sub_tokens(s, force_rich)
    if not s then return nil end
    local use_rich = force_rich or _opts.dw_original_spacing

    if use_rich then
        if not s.tokens_rich then
            local raw_text = normalize_inline_break_markers(s.text):gsub("\n", " ")
            s.tokens_rich = build_word_list_internal(raw_text, true)
        end
        return s.tokens_rich
    else
        if not s.tokens then
            local raw_text = normalize_inline_break_markers(s.text):gsub("\n", " ")
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

local function clean_text_srt(line)
    if not line then return "" end
    line = line:gsub("^\xEF\xBB\xBF", "")
    line = line:gsub("\r", ""):gsub("<[^>]+>", ""):gsub("%z", "")
    line = normalize_inline_break_markers(line)
    return line:gsub("^%s*(.-)%s*$", "%1")
end

local function calculate_ass_alpha(val)
    if type(val) == "string" and #val == 2 and val:match("%x%x") then
        return val:upper()
    end
    local num = tonumber(val)
    if not num then return "00" end
    -- Legacy numeric values are transparency percentages, not CSS-style opacity.
    -- Prefer explicit ASS alpha values: 00 is opaque, FF is fully transparent.
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

-- --- module exports --------------------------------------------------------
M.utf8_to_table = utf8_to_table
M.utf8_to_lower = utf8_to_lower
M.utf8_truncate = utf8_truncate
M.is_word_char = is_word_char
M.is_abbrev = is_abbrev
M.has_cyrillic = has_cyrillic
M.logical_cmp = logical_cmp
M.build_word_list_internal = build_word_list_internal
M.build_word_list = build_word_list
M.get_sub_tokens = get_sub_tokens
M.is_word_token = is_word_token
M.normalize_inline_break_markers = normalize_inline_break_markers
M.clean_text_srt = clean_text_srt
M.calculate_ass_alpha = calculate_ass_alpha
M.build_copy_preview = build_copy_preview
M.L_EPSILON = L_EPSILON

return M
