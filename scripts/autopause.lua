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

local is_holding_space = false
local space_down_time = 0
local space_tap_delay = 0 -- Threshold to distinguish tap vs hold (seconds)

local function check_sub()
    if not auto_pause_enabled then return end
    
    -- If user is holding Space, bypass all pausing completely
    if is_holding_space then return end

    -- Request texts from both primary and secondary tracks
    local raw_text_primary = mp.get_property("sub-text/ass") or mp.get_property("sub-text-ass") or ""
    local raw_text_secondary = mp.get_property("secondary-sub-text") or ""
    
    if raw_text_primary == "" and raw_text_secondary == "" then return end

    -- If "pause every word" mode is OFF, we look for the token to skip intermediate words.
    -- We check BOTH primary and secondary texts for the karaoke token.
    if not pause_every_word then
        local has_karaoke = string.find(raw_text_primary, karaoke_token, 1, true)
        if not has_karaoke then has_karaoke = string.find(raw_text_secondary, karaoke_token, 1, true) end
        
        if has_karaoke then
            return
        end
    end

    -- Start the timer for autopause based ONLY on the primary subtitle
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

-- AutoPause Toggle Logic
local function do_toggle_autopause()
    auto_pause_enabled = not auto_pause_enabled
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Autopause: " .. (auto_pause_enabled and "ON" or "OFF"), 0.5)
end

-- Karaoke Mode Toggle Logic
local function do_toggle_karaoke()
    pause_every_word = not pause_every_word
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    if pause_every_word then
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Pause Mode: EVERY WORD (Requires Karaoke)", 0.5)
    else
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Pause Mode: END OF PHRASE", 0.5)
    end
end

-- Smart Spacebar Logic
local function handle_smart_space(table)
    if table.event == "down" then
        is_holding_space = true
        space_down_time = mp.get_time()
        -- Immediately ensure player is playing while held
        mp.set_property_bool("pause", false)
    elseif table.event == "up" then
        is_holding_space = false
        local hold_duration = mp.get_time() - space_down_time
        
        -- If it was a quick tap, toggle the pause state normally
        if hold_duration < space_tap_delay then
            local is_paused = mp.get_property_bool("pause")
            mp.set_property_bool("pause", not is_paused)
        end
    end
end

-- Register functions to be bound in input.conf
mp.add_key_binding(nil, "toggle-autopause", do_toggle_autopause)
mp.add_key_binding(nil, "toggle-karaoke-mode", do_toggle_karaoke)
mp.add_key_binding(nil, "smart-space", handle_smart_space, {complex=true})