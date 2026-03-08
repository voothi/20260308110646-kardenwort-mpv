local mp = require 'mp'

-- =========================================================================
-- SCRIPT SETTINGS
-- =========================================================================

-- Is autopause enabled immediately upon player startup (true - yes, false - no)
local auto_pause_enabled = true

-- Pause on EVERY word in karaoke mode?
-- false = play the whole phrase and pause only at the end.
-- true = pause after every spoken word.
local pause_every_word = false

-- Hotkey to quickly toggle autopause on/off
local toggle_key = "Q"

-- Hotkey to toggle the "Pause every word" mode
local toggle_mode_key = "K"

-- Token used by the script to determine if the karaoke phrase is still being spoken.
local karaoke_token = "{\\c}"

-- How many seconds before the text disappears to pause the video
-- (0.15 is usually perfect to keep the text on the screen)
local pause_padding = 0.15

-- How often the script checks the time (in seconds). 
-- 0.05 is the optimal balance between pause accuracy and player load.
local check_interval = 0.05

-- =========================================================================
-- MAIN CODE (NO NEED TO CHANGE BELOW)
-- =========================================================================

local last_paused_sub_end = nil

local function check_sub()
    if not auto_pause_enabled then return end

    -- Request raw text with all ASS tags
    local raw_text = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass")
    if not raw_text or raw_text == "" then return end

    -- If "pause every word" mode is OFF, we look for the token to skip intermediate words.
    -- If ON, we simply ignore this block and always proceed to pause.
    if not pause_every_word then
        if string.find(raw_text, karaoke_token, 1, true) then
            return
        end
    end

    -- Start the timer for autopause
    local sub_end = mp.get_property_number("sub-end")
    local time_pos = mp.get_property_number("time-pos")

    if sub_end ~= nil and time_pos ~= nil then
        -- Pause the video the specified amount of time before the text disappears from the screen
        if (sub_end - time_pos) < pause_padding and (sub_end - time_pos) > 0 then
            if last_paused_sub_end ~= sub_end then
                mp.set_property_bool("pause", true)
                last_paused_sub_end = sub_end
            end
        end
    end
end

-- Start periodic timer check
mp.add_periodic_timer(check_interval, check_sub)

-- Register hotkey (toggle autopause itself)
mp.add_key_binding(toggle_key, "toggle-autopause", function()
    auto_pause_enabled = not auto_pause_enabled
    mp.osd_message("Autopause: " .. (auto_pause_enabled and "ON" or "OFF"), 2)
end)

-- Register hotkey (toggle karaoke mode)
mp.add_key_binding(toggle_mode_key, "toggle-karaoke-mode", function()
    pause_every_word = not pause_every_word
    if pause_every_word then
        mp.osd_message("Mode: PAUSE EVERY WORD", 2)
    else
        mp.osd_message("Mode: PAUSE AT END OF PHRASE", 2)
    end
end)