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
local toggle_key = "P"

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

    -- Request texts from both primary and secondary tracks
    local raw_text_primary = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass") or ""
    local raw_text_secondary = mp.get_property("secondary-sub-text") or ""
    
    if raw_text_primary == "" and raw_text_secondary == "" then return end

    -- If "pause every word" mode is OFF, we look for the token to skip intermediate words.
    -- We check primary ASS tags for {\c}, and BOTH texts for ★ in case the karaoke track is secondary.
    if not pause_every_word then
        local has_karaoke = string.find(raw_text_primary, karaoke_token, 1, true)
        if not has_karaoke then has_karaoke = string.find(raw_text_primary, "★", 1, true) end
        if not has_karaoke then has_karaoke = string.find(raw_text_secondary, "★", 1, true) end
        
        if has_karaoke then
            return
        end
    end

    -- Check both timing ends
    local sub_end_primary = mp.get_property_number("sub-end")
    local sub_end_secondary = mp.get_property_number("secondary-sub-end")
    local time_pos = mp.get_property_number("time-pos")

    if time_pos == nil then return end

    local function check_trigger_pause(s_end)
        if s_end ~= nil and (s_end - time_pos) < pause_padding and (s_end - time_pos) > 0 then
            if last_paused_sub_end ~= s_end then
                mp.set_property_bool("pause", true)
                last_paused_sub_end = s_end
                return true
            end
        end
        return false
    end

    if check_trigger_pause(sub_end_primary) then return end
    if check_trigger_pause(sub_end_secondary) then return end
end

-- Start periodic timer check
mp.add_periodic_timer(check_interval, check_sub)

-- AutoPause Toggle Logic
local function do_toggle_autopause()
    auto_pause_enabled = not auto_pause_enabled
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Autopause: " .. (auto_pause_enabled and "ON" or "OFF"), 2)
end

-- Karaoke Mode Toggle Logic
local function do_toggle_karaoke()
    pause_every_word = not pause_every_word
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    if pause_every_word then
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Mode: PAUSE EVERY WORD", 2)
    else
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Mode: PAUSE AT END OF PHRASE", 2)
    end
end
-- Register functions to be bound in input.conf
mp.add_key_binding(nil, "toggle-autopause", do_toggle_autopause)
mp.add_key_binding(nil, "toggle-karaoke-mode", do_toggle_karaoke)