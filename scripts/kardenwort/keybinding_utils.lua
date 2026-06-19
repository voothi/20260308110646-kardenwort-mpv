-- ===============================================================================
-- keybinding_utils.lua — Key expansion/validation + consolidated bind helper
-- Reads Options at call time via the injected `opts` reference (never copied).
-- ===============================================================================

local mp = require 'mp'

local M = {}

local Options

function M.init(opts)
    Options = opts
end

function M.is_valid_mpv_key(k_str)
    if not k_str or k_str == "" then return false end
    local base = k_str:gsub("Ctrl%+", ""):gsub("Shift%+", ""):gsub("Alt%+", ""):gsub("Meta%+", "")
    local _, count = base:gsub("[%z\1-\127\194-\244][\128-\191]*", "")
    if count > 1 and base:match("[%z\128-\255]") then return false end
    return true
end

-- Automatic Russian Layout Expansion
local EN_RU_MAP = {
    ["a"]="ф", ["b"]="и", ["c"]="с", ["d"]="в", ["e"]="у", ["f"]="а", ["g"]="п", ["h"]="р",
    ["i"]="ш", ["j"]="о", ["k"]="л", ["l"]="д", ["m"]="ь", ["n"]="т", ["o"]="щ", ["p"]="з",
    ["q"]="й", ["r"]="к", ["s"]="ы", ["t"]="е", ["u"]="г", ["v"]="м", ["w"]="ц", ["x"]="ч",
    ["y"]="н", ["z"]="я", ["["]="х", ["]"]="ъ", [";"]="ж", ["'"]="э", [","]="б", ["."]="ю", ["`"]="ё"
}

function M.expand_ru_keys(key_string, opt_name)
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
                -- Shift+e -> "У" only (uppercase Cyrillic, no Shift+ prefix).
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

-- Consolidated key registration helper (task 1.4).
-- Replaces the three near-identical bind() closures at the L10589/L10632/L10653
-- registration blocks. {forced=...} selects add_forced_key_binding vs add_key_binding;
-- {wrap=...} wraps fn in a closure (the copy/position variants did this).
-- Does NOT replace the search bind() at L8736 (different signature: settings arg,
-- search- prefix, paired with unbind).
function M.bind(opt, name, fn, flags)
    if not opt or opt == "" then return end
    flags = flags or {}
    local i = 1
    local expanded_keys = M.expand_ru_keys(opt, name)
    for _, key in ipairs(expanded_keys) do
        local bound_fn = fn
        if flags.wrap then
            bound_fn = function(t)
                return fn(t)
            end
        end
        if flags.forced then
            mp.add_forced_key_binding(key, name .. "-" .. i, bound_fn)
        else
            mp.add_key_binding(key, name .. "-" .. i, bound_fn)
        end
        i = i + 1
    end
end

return M
