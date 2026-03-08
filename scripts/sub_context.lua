local mp = require 'mp'

-- =========================================================================
-- DRUM CONTEXT MODE SETTINGS
-- =========================================================================
-- This script provides a "Drum" subtitle context mode (toggled via 'c').
-- It displays previous and future subtitles around the current active one, 
-- giving you complete context for fragmented or short sentences.
-- =========================================================================

local enabled = false

-- ***************** CONFIGURATION OPTIONS *****************
-- === Global Sizing ===
-- Overall font size of the drum text (active line). Set to 0 to dynamically match your normal mpv sub-font-size.
-- Try values like 55 or 60 to make both drums larger overall!
local drum_font_size = 34

-- Number of previous and next subtitles to show around the active line
local context_lines = 2

-- === Context Line Styling (The "Dimmed" lines) ===
-- Opacity of the context lines (Hex format: 00 is solid, FF is invisible. 88 is ~50% transparent)
local context_opacity = "80"
-- Color of the context lines (Hex format BGR: CCCCCC is light gray)
local context_color = "FFFFFF"
-- Should the context lines be bold? (1 = yes, 0 = no)
local context_bold = "0"
-- Size of context lines relative to the main active line (0.85 = 85% of normal size)
local context_size_multiplier = 0.85

-- === Active Line Styling ===
-- Opacity of the active line (00 is solid/fully visible)
local active_opacity = "00"
-- Color of the active line (Hex format BGR: FFFFFF is pure white)
local active_color = "FFFFFF"
-- Should the active line be bold? (1 = yes, 0 = no)
local active_bold = "0"
-- Size multiplier for the active line (1.0 = normal size, 1.2 = 20% larger, etc.)
local active_size_multiplier = 1.0

-- === Spacing ===
-- Gap between the active line and the context lines for the top subtitle.
-- (Negative values pull the context lines closer to the active line, 
-- compensating for invisible padding inside the font itself). Try -0.1 to -0.2.
local spacing_gap = -0.1
-- === Stacking Options (when both subtitles are at the bottom via 'y') ===
-- Multiplier to calculate the vertical distance between stacked drums. 
-- Reduce this (e.g. to 1.0 or 0.9) to bring the stacked drums closer together!
local stack_height_multiplier = 1.15
-- *********************************************************

local primary_subs = {}
local secondary_subs = {}

local osd = mp.create_osd_overlay("ass-events")
osd.res_x = 1920
osd.res_y = 1080

local was_sub_vis = true
local was_sec_sub_vis = true

local function parse_time(time_str)
    local h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+),(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+)%.(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    return 0
end

local function load_srt(path)
    if not path or path == "" then return {} end
    local f = io.open(path, "r")
    if not f then return {} end
    
    local subs = {}
    local current_sub = nil
    local state = "ID"
    
    for line in f:lines() do
        -- Remove HTML tags for clean OSD display and normalize returns
        line = line:gsub("\r", ""):gsub("<[^>]+>", "")
        
        if line == "" then
            if current_sub and current_sub.text ~= "" then
                table.insert(subs, current_sub)
            end
            current_sub = nil
            state = "ID"
        elseif state == "ID" then
            if line:match("^%d+$") then
                current_sub = {text = ""}
                state = "TIME"
            end
        elseif state == "TIME" then
            local start_str, end_str = string.match(line, "(%S+)%s+%-%->%s+(%S+)")
            if start_str and end_str then
                current_sub.start_time = parse_time(start_str)
                current_sub.end_time = parse_time(end_str)
                state = "TEXT"
            end
        elseif state == "TEXT" then
            if current_sub.text == "" then
                current_sub.text = line
            else
                current_sub.text = current_sub.text .. " " .. line
            end
        end
    end
    
    if current_sub and current_sub.text ~= "" then
        table.insert(subs, current_sub)
    end
    
    f:close()
    return subs
end

local function load_tracks()
    primary_subs = {}
    secondary_subs = {}
    
    local sid = mp.get_property_number("sid", 0)
    local ssid = mp.get_property_number("secondary-sid", 0)
    
    local tracks = mp.get_property_native("track-list")
    if not tracks then return end
    
    for _, t in ipairs(tracks) do
        if t.type == "sub" then
            if t.id == sid and t.external and t["external-filename"] then
                primary_subs = load_srt(t["external-filename"])
            end
            if t.id == ssid and t.external and t["external-filename"] then
                secondary_subs = load_srt(t["external-filename"])
            end
        end
    end
end

local function get_center_index(subs, time_pos)
    if not subs or #subs == 0 then return -1 end
    
    for i = 1, #subs do
        local sub = subs[i]
        if time_pos >= sub.start_time and time_pos <= sub.end_time then
            return i
        end
        if time_pos < sub.start_time then
            if i > 1 then
                local prev = subs[i-1]
                if (time_pos - prev.end_time) < (sub.start_time - time_pos) then
                    return i - 1
                else
                    return i
                end
            else
                return 1
            end
        end
    end
    return #subs
end

local function draw_drum(subs, center_idx, y_pos_percent, time_pos, font_size)
    if center_idx == -1 then return "" end
    
    local ass = ""
    local start_idx = math.max(1, center_idx - context_lines)
    local end_idx = math.min(#subs, center_idx + context_lines)
    
    local is_top = (y_pos_percent < 50)
    local y_pixel = y_pos_percent * 1080 / 100
    local gap = font_size * spacing_gap
    
    local function format_sub(sub, is_center)
        local is_active = (is_center and time_pos >= sub.start_time and time_pos <= sub.end_time)
        if is_active then
            return string.format("{\\alpha&H%s&}{\\b%s}{\\c&H%s&}{\\fs%d}%s{\\fs%d}", active_opacity, active_bold, active_color, font_size * active_size_multiplier, sub.text, font_size)
        else
            return string.format("{\\alpha&H%s&}{\\b%s}{\\c&H%s&}{\\fs%d}%s{\\fs%d}", context_opacity, context_bold, context_color, font_size * context_size_multiplier, sub.text, font_size)
        end
    end

    local prev_text = ""
    for i = start_idx, center_idx - 1 do
        if prev_text ~= "" then prev_text = prev_text .. "\\N" end
        prev_text = prev_text .. format_sub(subs[i], false)
    end
    
    local active_text = format_sub(subs[center_idx], true)
    
    local next_text = ""
    for i = center_idx + 1, end_idx do
        if next_text ~= "" then next_text = next_text .. "\\N" end
        next_text = next_text .. format_sub(subs[i], false)
    end
    
    if is_top then
        -- Top Subtitle: Anchor active line at the very top (Y), Prev lines above it
        if prev_text ~= "" then
            ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s\n", y_pixel - gap, font_size, prev_text)
        end
        local main_text = active_text
        if next_text ~= "" then main_text = main_text .. "\\N" .. next_text end
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s\n", y_pixel, font_size, main_text)
    else
        -- Bottom Subtitle: Build the whole block and anchor at the bottom (Y)
        -- so it naturally grows upwards and never goes below y_pixel (which is near the edge).
        local all_text = ""
        if prev_text ~= "" then all_text = prev_text .. "\\N" end
        all_text = all_text .. active_text
        if next_text ~= "" then all_text = all_text .. "\\N" .. next_text end
        
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s\n", y_pixel, font_size, all_text)
    end
    
    return ass
end

local update_timer = nil

local function update_osd()
    if not enabled then return end
    
    -- If the user has hidden subtitles via 's', clear the drum OSD and stop.
    if not was_sub_vis then
        osd.data = ""
        osd:update()
        return
    end
    
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end
    
    local ass_text = ""
    -- Use the native mpv subtitle size if explicit manual user size is not specified
    local font_size = drum_font_size > 0 and drum_font_size or mp.get_property_number("sub-font-size", 44)
    
    local pri_pos = mp.get_property_number("sub-pos", 95)
    local sec_pos = mp.get_property_number("secondary-sub-pos", 10)
    
    if sec_pos > 50 then
        -- Prevent collision by automatically stacking the secondary drum safely above the primary drum.
        -- We mathematically estimate the maximum possible height the primary drum can take in pixels.
        local max_lines = active_size_multiplier + (2 * context_lines * context_size_multiplier)
        local max_pixels = max_lines * font_size * stack_height_multiplier
        local max_percent = (max_pixels / 1080) * 100
        
        -- Position the top drum exactly above the calculated height of the bottom drum
        sec_pos = pri_pos - max_percent
    end
    
    if #secondary_subs > 0 then
        local idx = get_center_index(secondary_subs, time_pos)
        ass_text = ass_text .. draw_drum(secondary_subs, idx, sec_pos, time_pos, font_size)
    end
    
    if #primary_subs > 0 then
        local idx = get_center_index(primary_subs, time_pos)
        ass_text = ass_text .. draw_drum(primary_subs, idx, pri_pos, time_pos, font_size)
    end
    
    osd.data = ass_text
    osd:update()
end

local function toggle_sub_visibility()
    -- If Drum Mode is enabled, the native sub-visibility is already false.
    -- We use our tracked 'was_sub_vis' as the source of truth.
    local current_vis = enabled and was_sub_vis or mp.get_property_bool("sub-visibility", true)
    local next_vis = not current_vis
    
    if enabled then
        was_sub_vis = next_vis
        was_sec_sub_vis = next_vis
        -- Force an immediate OSD update to hide/show the drum
        update_osd()
    else
        mp.set_property_bool("sub-visibility", next_vis)
        mp.set_property_bool("secondary-sub-visibility", next_vis)
    end
    
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Subtitles: " .. (next_vis and "ON" or "OFF"), 2)
end

local function toggle_context()
    enabled = not enabled
    if enabled then
        -- Hide native subs to prevent overlapping
        was_sub_vis = mp.get_property_bool("sub-visibility", true)
        was_sec_sub_vis = mp.get_property_bool("secondary-sub-visibility", true)
        mp.set_property_bool("sub-visibility", false)
        mp.set_property_bool("secondary-sub-visibility", false)
        
        load_tracks()
        
        update_timer = mp.add_periodic_timer(0.05, update_osd)
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Drum Mode: ON", 2)
    else
        -- Restore native subs (fallback to true to fix watch-later bugs)
        mp.set_property_bool("sub-visibility", was_sub_vis ~= nil and was_sub_vis or true)
        mp.set_property_bool("secondary-sub-visibility", was_sec_sub_vis ~= nil and was_sec_sub_vis or true)
        
        if update_timer then
            update_timer:kill()
            update_timer = nil
        end
        osd:remove()
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Drum Mode: OFF", 2)
    end
end

mp.add_key_binding("c", "toggle-drum-mode", toggle_context)

-- Custom cycler for secondary subtitles to fix visibility and provide cleaner OSD
local function cycle_secondary_sid()
    -- Ensure natively visibility is forcibly turned back on, EXCEPT if drum mode is hiding it
    if enabled then
        was_sec_sub_vis = true
    else
        mp.set_property_bool("secondary-sub-visibility", true)
    end
    
    mp.command("no-osd cycle secondary-sid")
    
    local ssid = mp.get_property_number("secondary-sid", 0)
    if ssid == 0 then
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Secondary subtitles: OFF", 2.5)
        return
    end
    
    -- Wait a tiny moment for properties to update before getting track details
    mp.add_timeout(0.05, function()
        local tracks = mp.get_property_native("track-list")
        if not tracks then return end
        
        for _, t in ipairs(tracks) do
            if t.type == "sub" and t.id == ssid then
                local label = "ON"
                if t.lang then
                    label = t.lang:upper()
                elseif t.title then
                    label = t.title
                elseif t["external-filename"] then
                    local fname = t["external-filename"]:match("([^/\\]+)$") or t["external-filename"]
                    
                    -- Extract typical language codes like '.ru.srt' or '_en.ass'
                    local ext_lang = fname:match("%.([A-Za-z0-9_]+)%.srt$") or fname:match("%.([A-Za-z0-9_]+)%.ass$")
                    if ext_lang then
                        label = ext_lang:upper()
                    else
                        -- Fallback to the truncated filename
                        label = string.sub(fname, 1, 30)
                    end
                end
                local ass_enable = mp.get_property("osd-ass-cc/0") or ""
                mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Secondary subtitles: " .. label, 2.5)
                break
            end
        end
    end)
end

mp.add_key_binding(nil, "cycle-sec-sid", cycle_secondary_sid)
mp.add_key_binding(nil, "toggle-sub-visibility", toggle_sub_visibility)

-- Re-parse if track changes while drum mode is active
mp.observe_property("sid", "number", function() if enabled then load_tracks() end end)
mp.observe_property("secondary-sid", "number", function() if enabled then load_tracks() end end)

-- Prevent permanent subtitle breakage by restoring native subs if user quits player during Drum Mode
mp.register_event("shutdown", function()
    if enabled then
        mp.set_property_bool("sub-visibility", was_sub_vis ~= nil and was_sub_vis or true)
        mp.set_property_bool("secondary-sub-visibility", was_sec_sub_vis ~= nil and was_sec_sub_vis or true)
    end
end)
