local M = {}

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

return M
