-- ============================================================================
-- clipboard.lua — Platform-specific clipboard write + GoldenDict/TTS trigger
-- ============================================================================

local mp = require("mp")
local utils = require("mp.utils")

local M = {}

local FSM, Options, Tracks, Diagnostic
local _helpers

function M.init(fsm, opts, tracks, diag, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(tracks, "FATAL: tracks dependency missing")
    assert(diag, "FATAL: diag dependency missing")
    assert(helpers, "FATAL: helpers dependency missing")

    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diag
    _helpers = setmetatable(helpers, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end,
    })
end

-- --- vk_codes constant ---
local vk_codes = {
    ctrl = 0x11,
    alt = 0x12,
    shift = 0x10,
    win = 0x5B,
    a = 0x41,
    b = 0x42,
    c = 0x43,
    d = 0x44,
    e = 0x45,
    f = 0x46,
    g = 0x47,
    h = 0x48,
    i = 0x49,
    j = 0x4A,
    k = 0x4B,
    l = 0x4C,
    m = 0x4D,
    n = 0x4E,
    o = 0x4F,
    p = 0x50,
    q = 0x51,
    r = 0x52,
    s = 0x53,
    t = 0x54,
    u = 0x55,
    v = 0x56,
    w = 0x57,
    x = 0x58,
    y = 0x59,
    z = 0x5A,
    ["0"] = 0x30,
    ["1"] = 0x31,
    ["2"] = 0x32,
    ["3"] = 0x33,
    ["4"] = 0x34,
    ["5"] = 0x35,
    ["6"] = 0x36,
    ["7"] = 0x37,
    ["8"] = 0x38,
    ["9"] = 0x39,
    f1 = 0x70,
    f2 = 0x71,
    f3 = 0x72,
    f4 = 0x73,
    f5 = 0x74,
    f6 = 0x75,
    f7 = 0x76,
    f8 = 0x77,
    f9 = 0x78,
    f10 = 0x79,
    f11 = 0x7A,
    f12 = 0x7B,
    -- Cyrillic equivalents (ЙЦУКЕН)
    ["й"] = 0x51,
    ["ц"] = 0x57,
    ["у"] = 0x45,
    ["к"] = 0x52,
    ["е"] = 0x54,
    ["н"] = 0x59,
    ["г"] = 0x55,
    ["ш"] = 0x49,
    ["щ"] = 0x4F,
    ["з"] = 0x50,
    ["ф"] = 0x41,
    ["ы"] = 0x53,
    ["в"] = 0x44,
    ["а"] = 0x46,
    ["п"] = 0x47,
    ["р"] = 0x48,
    ["о"] = 0x4A,
    ["л"] = 0x4B,
    ["д"] = 0x4C,
    ["я"] = 0x5A,
    ["ч"] = 0x58,
    ["с"] = 0x43,
    ["м"] = 0x56,
    ["и"] = 0x42,
    ["т"] = 0x4E,
    ["ь"] = 0x4D,
    ["б"] = 0xBC,
    ["ю"] = 0xBE,
}

local function set_clipboard(text, mode)
    if text and text ~= "" then
        mp.set_property("user-data/kardenwort/last_clipboard", text)
    end
    -- Native property is unreliable on some Windows MPV builds for system-wide sync.
    -- We skip it on Windows to ensure PowerShell (which handles retries/encoding) is used.
    local platform = package.config:sub(1, 1)
    if platform ~= "\\" then
        local success = pcall(function()
            mp.set_property("clipboard", text)
        end)
        if success then
            return
        end
    end
    if platform == "\\" then
        local safe_txt = text:gsub("'", "''")
        local cmd = string.format(
            "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; for ($i=0; $i -lt %d; $i++) { try { Set-Clipboard -Value '%s' -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds %d } }",
            Options.win_clipboard_retries,
            safe_txt,
            Options.win_clipboard_retry_delay
        )
        utils.subprocess({
            args = { "powershell", "-NoProfile", "-Command", cmd },
            cancellable = false,
        })
    else
        local un = io.popen("uname -a")
        local uname_str = un and un:read("*a") or ""
        if un then
            un:close()
        end
        uname_str = uname_str:lower()

        local cmd = ""
        if uname_str:find("darwin") then
            cmd = "pbcopy"
        elseif
            uname_str:find("android")
            or (os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux"))
        then
            cmd = "termux-clipboard-set"
        elseif os.getenv("WAYLAND_DISPLAY") then
            cmd = "wl-copy"
        else
            cmd =
                "xclip -selection clipboard -i 2>/dev/null || xsel --clipboard --input 2>/dev/null"
        end

        if cmd ~= "" then
            local f = io.popen(cmd, "w")
            if f then
                f:write(text)
                f:close()
            end
        end
    end

    -- Optional explicit trigger for GoldenDict scan popup.
    -- This bypasses AHK polling latency by directly notifying the dictionary tool.
    -- Robust GoldenDict trigger (Improved layout/modifier stability)
    -- Professional Layout-Independent Trigger (VK-based)
    local user_hotkey = nil
    if
        Options.gd_trigger_enabled == "yes"
        and platform == "\\"
        and (mode == "side" or mode == "main")
    then
        user_hotkey = (mode == "main") and Options.gd_hotkey_main or Options.gd_hotkey_popup
    elseif
        Options.tts_trigger_enabled == "yes"
        and platform == "\\"
        and mode
        and mode:match("^tts_[1-8]$")
    then
        user_hotkey = Options["tts_hotkey_" .. mode:match("([1-8])$")]
    end
    if user_hotkey and user_hotkey ~= "" then
        local all_events = {}
        for hotkey in user_hotkey:gmatch("[^%s,;]+") do
            local primary = hotkey:lower()
            local events = {}
            local modifiers = { "ctrl", "alt", "shift", "win" }

            -- Handle implicit shift from uppercase keys (e.g. "Ctrl+Alt+Q")
            local main_key = hotkey:match("[^+]+$")
            local needs_shift = (main_key and #main_key == 1 and main_key:match("%u"))
                or primary:find("shift")

            for _, mod in ipairs(modifiers) do
                if mod ~= "shift" and primary:find(mod) then
                    table.insert(events, { vk_codes[mod], 0 })
                end
            end
            if needs_shift then
                table.insert(events, { vk_codes.shift, 0 })
            end

            -- Get the main key (the last part)
            local key = main_key:lower()
            if key and vk_codes[key] then
                table.insert(events, { vk_codes[key], 0 }) -- Down
                table.insert(events, { vk_codes[key], 2 }) -- Up
            end

            -- Release modifiers in reverse order
            for i = #events - 1, 1, -1 do
                if events[i][2] == 0 then
                    table.insert(events, { events[i][1], 2 })
                end
            end

            for _, ev in ipairs(events) do
                table.insert(all_events, ev)
            end
        end

        if #all_events == 0 then
            return
        end

        -- Configurable Trigger Lock (Prevent AHK Recursion)
        local now = mp.get_time()
        if (now - (FSM.LAST_TRIGGER_TIME or 0)) < Options.gd_trigger_lock_duration then
            -- A trigger was recently fired, likely by the user.
            -- Any subsequent ^c from AHK should just update the clipboard without re-triggering.
            return
        end
        FSM.LAST_TRIGGER_TIME = now

        -- Independent Mode Delays (Popup/Main)
        if Options.gd_trigger_method == "python" then
            local delay = (mode == "main") and Options.python_trigger_delay_main
                or Options.python_trigger_delay_popup
            local py_cmd = string.format(
                "import ctypes, time; time.sleep(%f); u=ctypes.windll.user32; ",
                delay
            )
            for _, ev in ipairs(all_events) do
                py_cmd = py_cmd .. string.format("u.keybd_event(0x%X,0,%d,0); ", ev[1], ev[2])
            end
            mp.command_native_async({
                name = "subprocess",
                args = { Options.python_path, "-c", py_cmd },
                playback_only = false,
                capture_stdout = false,
                capture_stderr = false,
            }, function() end)
        else
            -- Robust VK Injector via PowerShell Add-Type (Default)
            local type_name = "Win32K" .. os.time()
            local signature =
                '[DllImport("user32.dll")] public static extern void keybd_event(byte b, byte s, uint f, uint e);'
            local script = string.format(
                "$t = Add-Type -MemberDefinition '%s' -Name '%s' -Namespace 'Win32' -PassThru;",
                signature,
                type_name
            )

            for _, ev in ipairs(all_events) do
                script = script .. string.format("$t::keybd_event(0x%X,0,%d,0);", ev[1], ev[2])
            end

            mp.command_native_async({
                name = "subprocess",
                args = { "powershell", "-NoProfile", "-Command", script },
                playback_only = false,
                capture_stdout = false,
                capture_stderr = false,
            }, function() end)
        end
    end
end

M.set_clipboard = set_clipboard

return M
