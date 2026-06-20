-- ===============================================================================
-- help_hud.lua — F1 Help HUD feature for kardenwort
-- Contains HELP_SCHEMA, key-display normalization, key-discovery, the
-- render_help renderer, scroll/keymap lifecycle, and cmd_toggle_help.
-- The help_osd_* overlays are created in main.lua and injected via helpers
-- (read at call time). render_search is also injected (cross-feature: help
-- toggle clears the search overlay).
-- ===============================================================================

local mp = require 'mp'
local keybinding_utils = require 'keybinding_utils'

local M = {}

local FSM, Options
local _helpers

function M.init(fsm, opts, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    FSM = fsm
    Options = opts
    _helpers = setmetatable(helpers or {}, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end
    })
end

-- Helpers read at call time (defined/assigned in main.lua).
-- Referenced directly via _helpers table — no wrapper call frames needed.
local function expand_ru_keys(raw, name) return keybinding_utils.expand_ru_keys(raw, name) end

-- --- key display normalization -------------------------------------------

local function normalize_key_display(k)
    if k == nil or k == "" then return k end
    local parts = {}
    for p in k:gmatch("[^+]+") do table.insert(parts, p) end

    local last = parts[#parts]
    local lower = nil

    if #last == 1 then
        if last:upper() == last and last:lower() ~= last then
            lower = last:lower()
        end
    elseif #last == 2 then
        local b1, b2 = last:byte(1, 2)
        if b1 == 208 then
            if b2 >= 144 and b2 <= 159 then
                lower = string.char(208, b2 + 32)
            elseif b2 >= 160 and b2 <= 175 then
                lower = string.char(209, b2 - 32)
            elseif b2 == 129 then
                lower = string.char(209, 145)
            end
        end
    end

    if lower then
        local has_shift = false
        for i=1, #parts-1 do
            if parts[i]:lower() == "shift" then has_shift = true break end
        end
        if not has_shift then
            table.insert(parts, #parts, "Shift")
        end
        parts[#parts] = lower
        return table.concat(parts, "+")
    end
    return k
end

local function get_keys_for_action(cmd_pattern, whitelist, fallback_keys)
    local bindings = mp.get_property_native("input-bindings") or {}
    local keys = {}
    local seen = {}

    local active_cmds = {}
    for _, b in ipairs(bindings) do
        local k = normalize_key_display(b.key)
        if k and k ~= "" then
            active_cmds[k] = b.cmd
        end
    end

    local function prepare_pattern(raw)
        local p = raw
        if not p:find("%%") and not p:find("%.%*") and not p:find("%.%-") then
            p = p:gsub("([%-%+%.%[%]%*%?])", "%%%1")
        end
        return p
    end

    local function cmd_matches(binding_cmd)
        if type(cmd_pattern) == "table" then
            for _, raw in ipairs(cmd_pattern) do
                local p = prepare_pattern(raw)
                if binding_cmd:find(p) then return true end
            end
            return false
        end
        local p = prepare_pattern(cmd_pattern)
        return binding_cmd:find(p) ~= nil
    end

    for _, b in ipairs(bindings) do
        local k = normalize_key_display(b.key)
        if k == nil or k == "" then goto continue end

        local is_mouse = k:find("MBTN") or k:find("WHEEL")
        if is_mouse and (not whitelist or not whitelist[k]) then goto continue end

        if whitelist then
            if not whitelist[k] and not whitelist[k:upper()] then goto continue end
        end

        if type(cmd_pattern) == "string" and (cmd_pattern == "fullscreen" or cmd_pattern == "cycle fullscreen") and k == "ESC" and (not whitelist or not whitelist["ESC"]) then
            goto continue
        end

        if cmd_matches(b.cmd) and active_cmds[k] == b.cmd then
            if not seen[k] and k ~= "" and k ~= nil then
                table.insert(keys, k)
                seen[k] = true
            end
        end
        ::continue::
    end

    if #keys == 0 and fallback_keys then
        local raw = fallback_keys
        if type(raw) == "function" then raw = raw() end
        if type(raw) == "string" and raw ~= "" then
            local expanded = expand_ru_keys(raw, "help-fallback")
            for _, k0 in ipairs(expanded) do
                local k = normalize_key_display(k0)
                if k and k ~= "" and not seen[k] then
                    if whitelist then
                        if whitelist[k] or whitelist[k:upper()] then
                            table.insert(keys, k)
                            seen[k] = true
                        end
                    else
                        table.insert(keys, k)
                        seen[k] = true
                    end
                end
            end
        end
    end

    return keys
end

local function wrap_by_words(text, max_chars)
    if not text or text == "" then return {"Unbound"} end
    if max_chars == nil or max_chars < 8 then return {text} end
    local out, line = {}, ""
    for token in text:gmatch("%S+") do
        if line == "" then
            line = token
        elseif (#line + 1 + #token) <= max_chars then
            line = line .. " " .. token
        else
            table.insert(out, line)
            line = token
        end
    end
    if line ~= "" then table.insert(out, line) end
    if #out == 0 then out = {"Unbound"} end
    return out
end

-- --- HELP schema ----------------------------------------------------------

local HELP_SCHEMA = {
    { category = "Interface Modes", actions = {
        { desc = "Toggle Drum Window (W)", cmd = "kardenwort/toggle-drum-window" },
        { desc = "Toggle Drum Mode", cmd = "kardenwort/toggle-drum-mode" },
        { desc = "Toggle Subtitle Visibility", cmd = "kardenwort/toggle-sub-visibility" },
        { desc = "Toggle Book Mode", cmd = "kardenwort/toggle-book-mode" },
        { desc = "Cycle Secondary Subtitle Position", cmd = "kardenwort/cycle-secondary-pos" },
        { desc = "Cycle Secondary Subtitle Track", cmd = "kardenwort/cycle-sec-sid" },
        { desc = "Toggle Search HUD", cmd = "kardenwort/toggle-drum-search" },
        { desc = "Toggle OSC Visibility", cmd = "kardenwort/toggle-osc-visibility" },
    }},
    { category = "Navigation", actions = {
        { desc = "Previous Subtitle", cmd = "kardenwort/seek_prev" },
        { desc = "Next Subtitle", cmd = "kardenwort/seek_next" },
        { desc = "Seek Backward (2s)", cmd = "kardenwort/seek_time_backward" },
        { desc = "Seek Forward (2s)", cmd = "kardenwort/seek_time_forward" },
    }},
    { category = "Immersion Features", actions = {
        { desc = "Smart Space (Hold=Play)", cmd = "kardenwort/smart-space", whitelist = {["SPACE"]=true} },
        { desc = "Subtitle Replay / Loop", cmd = "kardenwort/replay-subtitle" },
        { desc = "Toggle Autopause", cmd = "kardenwort/toggle-autopause" },
        { desc = "Cycle Immersion Mode", cmd = "kardenwort/cycle-immersion-mode" },
        { desc = "Toggle Karaoke Mode", cmd = "kardenwort/toggle-karaoke-mode" },
    }},
    { category = "Mining & Tools", actions = {
        { desc = "Copy Subtitle", cmd = "kardenwort/copy-subtitle" },
        { desc = "Copy Subtitle (Popup)", cmd = "kardenwort%-global%-copy%-side" },
        { desc = "Copy Subtitle (Main)", cmd = "kardenwort%-global%-copy%-main" },
        { desc = "TTS EN (copy + trigger)", cmd = "kardenwort/copy-subtitle-tts-2", fallback_keys = function() return Options.key_tts_2 end },
        { desc = "TTS DE (copy + trigger)", cmd = "kardenwort/copy-subtitle-tts-3", fallback_keys = function() return Options.key_tts_3 end },
        { desc = "TTS RU (copy + trigger)", cmd = "kardenwort/copy-subtitle-tts-4", fallback_keys = function() return Options.key_tts_4 end },
        { desc = "TTS UK (copy + trigger)", cmd = "kardenwort/copy-subtitle-tts-5", fallback_keys = function() return Options.key_tts_5 end },
        { desc = "Cycle Copy Mode (A/B)", cmd = "kardenwort/cycle-copy-mode" },
        { desc = "Toggle Context Copy", cmd = "kardenwort/toggle-copy-context" },
        { desc = "Open Record (TSV) File", cmd = "kardenwort/toggle-record-file" },
        { desc = "Toggle Global Highlights", cmd = "kardenwort/toggle-anki-global" },
    }},
    { category = "Drum Window: Actions", actions = {
        { desc = "DW Pair Toggle (Pink)", cmd = "dw%-pair" },
        { desc = "DW Add (Yellow)", cmd = "dw%-add", whitelist = {["g"]=true, ["п"]=true, ["MBTN_MID"]=true, ["Ctrl+MBTN_MID"]=true} },
        { desc = "DW Selection Click", cmd = "dw%-select%-%d+$", whitelist = {["MBTN_LEFT"]=true}, fallback_keys = function() return Options.dw_key_select end },
        { desc = "DW Copy Selection", cmd = "dw%-copy" },
        { desc = "DW Seek Selected", cmd = "dw%-seek%-%d+$", fallback_keys = function() return Options.dw_key_seek end },
        { desc = "DW Esc / Reset", cmd = "dw%-esc%-%d+$", whitelist = {["ESC"]=true}, fallback_keys = function() return Options.dw_key_esc end },
        { desc = "DW Tooltip Pin", cmd = "dw%-tooltip%-pin", whitelist = {["MBTN_RIGHT"]=true} },
        { desc = "DW Tooltip Hover", cmd = "dw%-tooltip%-hover" },
        { desc = "DW Tooltip Toggle", cmd = "dw%-tooltip%-toggle" },
    }},
    { category = "Drum Window: Navigation", actions = {
        { desc = "DW Prev/Next Subtitle", cmd = {"dw%-seek%-prev", "dw%-seek%-next"} },
        { desc = "DW Word Jump Left/Right", cmd = {"dw%-jump%-left", "dw%-jump%-right"} },
        { desc = "DW Scroll Up/Down", cmd = "dw%-scroll%-" },
        { desc = "DW Select Jump Up/Down", cmd = {"dw%-jump%-select%-up", "dw%-jump%-select%-down"} },
        { desc = "DW Select Left/Right", cmd = {"dw%-select%-left", "dw%-select%-right"} },
        { desc = "DW Select Up/Down", cmd = {"dw%-select%-up", "dw%-select%-down"} },
        { desc = "DW Open Record", cmd = "dw%-open%-record" },
        { desc = "DW Cycle Esc Mode", cmd = "dw%-cycle%-esc%-mode" },
        { desc = "DW Cycle Copy Mode", cmd = "dw%-cycle%-copy%-mode" },
        { desc = "DW Toggle Copy Context", cmd = "dw%-toggle%-copy%-context" },
    }},
    { category = "Search Window", actions = {
        { desc = "Toggle Search HUD", cmd = "kardenwort/toggle-drum-search" },
        { desc = "Move Result Up/Down", cmd = {"search%-up%-?", "search%-down%-?", "search%-wheel%-up%-?", "search%-wheel%-down%-?"}, fallback_keys = "UP DOWN WHEEL_UP WHEEL_DOWN", whitelist = {["UP"]=true, ["DOWN"]=true, ["WHEEL_UP"]=true, ["WHEEL_DOWN"]=true} },
        { desc = "Cursor Left/Right", cmd = {"search%-left%-?", "search%-right%-?"}, fallback_keys = "LEFT RIGHT" },
        { desc = "Select Left/Right", cmd = {"search%-left%-shift%-?", "search%-right%-shift%-?"}, fallback_keys = function() return (Options.search_key_select_left or "") .. " " .. (Options.search_key_select_right or "") end },
        { desc = "Jump Word Left/Right", cmd = {"search%-left%-ctrl%-?", "search%-right%-ctrl%-?"}, fallback_keys = function() return (Options.search_key_jump_left or "") .. " " .. (Options.search_key_jump_right or "") end },
        { desc = "Jump+Select Left/Right", cmd = {"search%-left%-ctrl%-shift%-?", "search%-right%-ctrl%-shift%-?"}, fallback_keys = function() return (Options.search_key_jump_select_left or "Ctrl+Shift+LEFT") .. " " .. (Options.search_key_jump_select_right or "Ctrl+Shift+RIGHT") end },
        { desc = "Backspace / Delete", cmd = {"search%-bs%-?", "search%-del%-?"}, fallback_keys = function() return (Options.search_key_bs or "") .. " " .. (Options.search_key_del or "") end },
        { desc = "Paste Clipboard", cmd = "search%-paste%-?", fallback_keys = function() return Options.search_key_paste end },
        { desc = "Select All", cmd = "search%-select%-all%-?", fallback_keys = function() return Options.search_key_select_all end },
        { desc = "Delete Prev Word", cmd = "search%-delete%-word%-?", fallback_keys = function() return Options.search_key_delete_word end },
        { desc = "Seek To Selected", cmd = "search%-seek%-selected%-?", fallback_keys = function() return Options.search_key_enter end },
        { desc = "Close Search", cmd = "search%-close%-?", fallback_keys = function() return Options.search_key_esc end },
    }},
    { category = "Subtitle Position & Delay", actions = {
        { desc = "Primary Subtitle Up", cmd = "kardenwort%-sub%-pos%-up" },
        { desc = "Primary Subtitle Down", cmd = "kardenwort%-sub%-pos%-down" },
        { desc = "Secondary Subtitle Up", cmd = "kardenwort%-sec%-sub%-pos%-up" },
        { desc = "Secondary Subtitle Down", cmd = "kardenwort%-sec%-sub%-pos%-down" },
        { desc = "Subtitle Delay Decrease", cmd = "sub%-delay.-%-" },
        { desc = "Subtitle Delay Increase", cmd = "sub%-delay.-%+" },
    }},
    { category = "Standard Controls", actions = {
        { desc = "Toggle Help HUD", cmd = "kardenwort/toggle-help", whitelist = {["F1"]=true} },
        { desc = "Cycle Audio Track", cmd = "kardenwort/cycle-audio" },
        { desc = "Adjust Volume", cmd = "volume", whitelist = {["9"]=true, ["0"]=true} },
        { desc = "Adjust Playback Speed", cmd = "speed" },
        { desc = "Frame Step Fwd/Back", cmd = "frame.*step", whitelist = {["."]=true, [","]=true, ["ю"]=true, ["б"]=true} },
        { desc = "Toggle Fullscreen", cmd = "cycle fullscreen", whitelist = {["v"]=true, ["м"]=true} },
        { desc = "Debug Console", cmd = "console/enable", whitelist = {["`"]=true, ["ё"]=true} },
        { desc = "Quit Player", cmd = "quit", whitelist = {["~"]=true, ["Ё"]=true} },
    }}
}

local function load_help_overrides()
    local path = mp.get_property("input-conf-path")
    if not path or path == "" then return end

    local f = io.open(path, "r")
    if not f then return end

    for line in f:lines() do
        local pattern, desc, wl_str = line:match("^#%s*@help:%s*([^|]+)%s*|%s*([^|]+)%s*|?%s*(.*)")
        if pattern then
            pattern = pattern:gsub("%s+$", ""):gsub("^%s+", "")
            desc = desc:gsub("%s+$", ""):gsub("^%s+", "")

            for _, cat in ipairs(HELP_SCHEMA) do
                for _, act in ipairs(cat.actions) do
                    if act.cmd == pattern then
                        act.desc = desc
                        if wl_str and wl_str ~= "" then
                            act.whitelist = {}
                            for key in wl_str:gmatch("[^,%s]+") do
                                act.whitelist[key] = true
                                act.whitelist[key:upper()] = true
                            end
                        end
                        goto next_line
                    end
                end
            end
        end
        ::next_line::
    end
    f:close()
end

-- --- renderer + lifecycle -------------------------------------------------

local render_help

local function help_scroll(direction)
    if not FSM.HELP_MODE then return end
    local step = math.max(20, Options.help_font_size * 1.25)
    FSM.HELP_SCROLL_OFFSET = math.max(0, math.min(FSM.HELP_SCROLL_MAX or 0, FSM.HELP_SCROLL_OFFSET + (direction * step)))
    render_help()
end

render_help = function()
    if not FSM.HELP_MODE then
        local bg = _helpers.help_osd_bg
        local title = _helpers.help_osd_title
        local o1 = _helpers.help_osd_1
        local o2 = _helpers.help_osd_2
        if bg then bg.data = ""; bg:update() end
        if title then title.data = ""; title:update() end
        if o1 then o1.data = ""; o1:update() end
        if o2 then o2.data = ""; o2:update() end
        return
    end

    local ry = Options.font_base_height
    local rx = math.floor(ry * 16 / 9)
    local box_w, box_h = rx * 0.9, ry * 0.85

    local ass_bg = ""
    local box_left = math.floor((rx - box_w) / 2)
    local box_top = math.floor((ry - box_h) / 2)
    ass_bg = ass_bg .. string.format("{\\an7}{\\pos(%d,%d)}", box_left, box_top)
    ass_bg = ass_bg .. string.format("{\\1c&H%s&\\1a&H%s&}", Options.help_bg_color, Options.help_bg_opacity)
    ass_bg = ass_bg .. string.format("{\\p1}m 0 0 l %d 0 l %d %d l 0 %d l 0 0 {\\p0}", box_w, box_w, box_h, box_h)
    local bg = _helpers.help_osd_bg
    bg.data = ass_bg
    bg:update()

    local ass_title = ""
    ass_title = ass_title .. string.format("{\\an8}{\\pos(%d,%d)}{\\fn%s}{\\fs%d}{\\b1}{\\bord0}{\\shad0}{\\4a&HFF&}{\\1c&H%s&}KARDENWORT SHORTCUT REFERENCE{\\b0}",
        rx/2, ry/2 - box_h/2 + 40, Options.help_font_name, Options.help_font_size * 1.2, Options.help_title_color)
    local title = _helpers.help_osd_title
    title.data = ass_title
    title:update()

    local clip_y1 = ry/2 - box_h/2 + 110
    local clip_y2 = ry/2 + box_h/2 - 40
    local clip_tag = string.format("{\\clip(0,%d,%d,%d)}", clip_y1, rx, clip_y2)

    local function format_category(cat)
        local line_count = 0
        local res = string.format("{\\b1}{\\1c&H%s&}{\\fs%d}%s{\\fs%d}{\\b0}\\N",
            Options.help_title_color, Options.help_font_size * 0.9, cat.category:upper(), Options.help_font_size * 0.8)
        line_count = line_count + 1
        local row_chars = math.max(48, math.floor((box_w * 0.43) / (Options.help_font_size * 0.55)))
        local desc_chars = 28
        local key_wrap_chars = math.max(14, row_chars - desc_chars - 2)
        local key_wrap_cont = math.max(20, row_chars - desc_chars)
        for _, act in ipairs(cat.actions) do
            local keys = get_keys_for_action(act.cmd, act.whitelist, act.fallback_keys)
            local key_str = (#keys > 0) and table.concat(keys, " ") or "Unbound"
            key_str = key_str:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            local key_lines = wrap_by_words(key_str, key_wrap_chars)

            local desc = act.desc
            local desc_pad = string.rep(" ", math.max(1, desc_chars - #desc))
            res = res .. string.format("{\\1c&H%s&}%s%s {\\1c&H%s&}%s\\N", Options.help_text_color, desc, desc_pad, Options.help_key_color, key_lines[1] or "Unbound")
            line_count = line_count + 1
            if #key_lines > 1 then
                local cont_pad = string.rep(" ", desc_chars + 1)
                for i=2, #key_lines do
                    local cont_parts = wrap_by_words(key_lines[i], key_wrap_cont)
                    for _, part in ipairs(cont_parts) do
                        res = res .. string.format("{\\1c&H%s&}%s{\\1c&H%s&}%s\\N", Options.help_text_color, cont_pad, Options.help_key_color, part)
                        line_count = line_count + 1
                    end
                end
            end
        end
        return res .. "\\N", line_count + 1
    end

    local col1_block, col2_block = "", ""
    local col1_lines, col2_lines = 0, 0
    local cat_blocks = {}
    for _, cat in ipairs(HELP_SCHEMA) do
        local block, lines = format_category(cat)
        table.insert(cat_blocks, { block = block, lines = lines })
    end
    for _, cb in ipairs(cat_blocks) do
        if col1_lines <= col2_lines then
            col1_block = col1_block .. cb.block
            col1_lines = col1_lines + cb.lines
        else
            col2_block = col2_block .. cb.block
            col2_lines = col2_lines + cb.lines
        end
    end

    local max_lines = math.max(col1_lines, col2_lines)
    local line_h = Options.help_font_size * 0.95
    local viewport_h = math.max(1, clip_y2 - clip_y1 - 20)
    FSM.HELP_SCROLL_MAX = math.max(0, (max_lines * line_h) - viewport_h)
    if FSM.HELP_SCROLL_OFFSET > FSM.HELP_SCROLL_MAX then
        FSM.HELP_SCROLL_OFFSET = FSM.HELP_SCROLL_MAX
    end

    local col1_x = rx/2 - box_w/2 + 80
    local col2_x = rx/2 + 60
    local start_y = clip_y1 + 10 - FSM.HELP_SCROLL_OFFSET
    local base_tags = string.format("{\\an7}{\\fn%s}{\\fs%d}{\\bord0}{\\shad0}{\\4a&HFF&}%s", Options.help_font_name, Options.help_font_size * 0.8, clip_tag)
    local col1_text = string.format("{\\pos(%d,%d)}%s%s", col1_x, start_y, base_tags, col1_block)
    local col2_text = string.format("{\\pos(%d,%d)}%s%s", col2_x, start_y, base_tags, col2_block)

    local o1 = _helpers.help_osd_1
    local o2 = _helpers.help_osd_2
    o1.data = col1_text
    o2.data = col2_text
    o1:update()
    o2:update()
end

local function bind_help_keymap()
    mp.add_forced_key_binding("UP", "help-scroll-up", function() help_scroll(-1) end, {repeatable = true})
    mp.add_forced_key_binding("DOWN", "help-scroll-down", function() help_scroll(1) end, {repeatable = true})
    mp.add_forced_key_binding("WHEEL_UP", "help-wheel-up", function() help_scroll(-1) end)
    mp.add_forced_key_binding("WHEEL_DOWN", "help-wheel-down", function() help_scroll(1) end)
    mp.add_forced_key_binding("ESC", "help-close-esc", function() M.cmd_toggle_help() end)
    mp.add_forced_key_binding("F1", "help-close-f1", function() M.cmd_toggle_help() end)
end

local function unbind_help_keymap()
    mp.remove_key_binding("help-scroll-up")
    mp.remove_key_binding("help-scroll-down")
    mp.remove_key_binding("help-wheel-up")
    mp.remove_key_binding("help-wheel-down")
    mp.remove_key_binding("help-close-esc")
    mp.remove_key_binding("help-close-f1")
end

function M.cmd_toggle_help()
    FSM.HELP_MODE = not FSM.HELP_MODE
    if FSM.HELP_MODE then
        FSM.SEARCH_MODE = false
        FSM.HELP_SCROLL_OFFSET = 0
        _helpers.render_search()
        bind_help_keymap()
    else
        unbind_help_keymap()
    end
    render_help()
end

-- Load input-conf @help overrides at module load time (only uses mp + HELP_SCHEMA).
M.load_overrides = function() load_help_overrides() end

M.normalize_key_display = normalize_key_display
M.get_keys_for_action = get_keys_for_action
M.wrap_by_words = wrap_by_words
M.render_help = render_help

return M
