local M = {}
local L_EPSILON = 0.0001

function M.calculate_ass_alpha(val)
    if type(val) == "string" and #val == 2 and val:match("%x%x") then
        return val:upper()
    end
    local num = tonumber(val)
    if not num then return "00" end
    if num >= 0 and num <= 1 then
        num = (1.0 - num) * 100
    end
    num = math.max(0, math.min(100, num))
    local hex = string.format("%02X", math.floor((num / 100) * 255 + 0.5))
    return hex
end

function M.utf8_to_table(str)
    local t = {}
    for ch in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(t, ch)
    end
    return t
end

function M.is_valid_mpv_key(k_str)
    if not k_str or k_str == "" then return false end
    local base = k_str:gsub("Ctrl%+", ""):gsub("Shift%+", ""):gsub("Alt%+", ""):gsub("Meta%+", "")
    local _, count = base:gsub("[%z\1-\127\194-\244][\128-\191]*", "")
    if count > 1 and base:match("[%z\128-\255]") then return false end
    return true
end

local CYRILLIC_UPPER = M.utf8_to_table("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯÄÖÜẞ")
local CYRILLIC_LOWER = M.utf8_to_table("абвгдеёжзийклмнопрстуфхцчшщъыьэюяäöüß")

local CYRILLIC_MAP = {}
for i = 1, #CYRILLIC_UPPER do
    CYRILLIC_MAP[CYRILLIC_UPPER[i]] = CYRILLIC_LOWER[i]
end

local WORD_CHAR_MAP = {}
for _, ch in ipairs(CYRILLIC_UPPER) do WORD_CHAR_MAP[ch] = true end
for _, ch in ipairs(CYRILLIC_LOWER) do WORD_CHAR_MAP[ch] = true end

function M.utf8_to_lower(str)
    local res = str:lower()
    return (res:gsub("[%z\1-\127\194-\244][\128-\191]*", CYRILLIC_MAP))
end

function M.is_word_char(c)
    if not c or #c == 0 then return false end
    if c:match("^[%w']$") then return true end
    return WORD_CHAR_MAP[c] == true
end

function M.logical_cmp(a, b)
    if not a or not b then return false end
    return math.abs(a - b) < L_EPSILON
end

function M.build_word_list_internal(text, keep_spaces)
    local tokens = {}
    if not text then return tokens end

    local chars = M.utf8_to_table(text)
    local i = 1
    local n = #chars
    local curr_logical_idx = 1
    local curr_sub_idx = 0.1
    local curr_visual_idx = 1

    while i <= n do
        local c = chars[i]
        local token = { text = "", is_word = false, logical_idx = nil, visual_idx = curr_visual_idx }

        if c == "{" then
            local start = i
            while i <= n and chars[i] ~= "}" do i = i + 1 end
            token.text = table.concat(chars, "", start, math.min(i, n))
            i = i + 1
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
        elseif M.is_word_char(c) then
            local start = i
            while i <= n and M.is_word_char(chars[i]) do i = i + 1 end
            token.text = table.concat(chars, "", start, i - 1)
            token.is_word = true
            token.lower_clean = M.utf8_to_lower(token.text:gsub("[%p%s]", ""))
            token.logical_idx = curr_logical_idx
            curr_logical_idx = curr_logical_idx + 1
            curr_sub_idx = 0.1
        elseif c == "\\" and i < n and (chars[i+1] == "N" or chars[i+1] == "n" or chars[i+1] == "h") then
            token.text = c .. chars[i+1]
            token.logical_idx = (curr_logical_idx - 1) + curr_sub_idx
            curr_sub_idx = curr_sub_idx + 0.1
            i = i + 2
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

function M.find_fuzzy_indices(str_lower, query_lower)
    if query_lower == "" then return {} end
    local str_t = M.utf8_to_table(str_lower)
    local query_t = M.utf8_to_table(query_lower)
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

function M.calculate_match_score(str, query)
    if query == "" then return 0 end
    local str_lower = M.utf8_to_lower(str)
    local query_lower = M.utf8_to_lower(query)
    if str_lower == query_lower then return 2000 end

    local tokens = {}
    for token in query_lower:gmatch("%S+") do
        table.insert(tokens, token)
    end
    if #tokens == 0 then return 0 end

    local matches = {}
    for _, token in ipairs(tokens) do
        local start_pos = str_lower:find(token, 1, true)
        if start_pos then
            local indices = {}
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
            local token_char_len = #M.utf8_to_table(token)
            for k = 1, token_char_len do
                table.insert(indices, char_start + k)
            end
            table.insert(matches, { indices = indices, literal = true, span = token_char_len })
        else
            local indices = M.find_fuzzy_indices(str_lower, token)
            if not indices then return 0 end
            local span = indices[#indices] - indices[1] + 1
            table.insert(matches, { indices = indices, literal = false, span = span })
        end
    end

    local score = 1000
    local all_indices = {}
    for _, m in ipairs(matches) do
        score = score + (m.literal and 250 or 120)
        score = score + math.max(0, 80 - (m.span - 1) * 6)
        for _, idx in ipairs(m.indices) do
            all_indices[idx] = true
        end
    end
    local covered = 0
    local flat_indices = {}
    for idx in pairs(all_indices) do
        covered = covered + 1
        table.insert(flat_indices, idx)
    end
    table.sort(flat_indices)
    score = score + math.min(180, covered * 8)
    return score, flat_indices
end

return M
