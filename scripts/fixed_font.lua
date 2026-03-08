local mp = require 'mp'

-- ==========================================
-- SCRIPT SETTINGS
-- ==========================================
-- Base window height (e.g. 1080p).
-- When the window is smaller than this, subtitles will stop shrinking.
local base_height = 1080 

-- Your preferred size multiplier
local base_scale = 1.0  
-- ==========================================

local function update_scale()
    local dim = mp.get_property_native("osd-dimensions")
    if not dim or dim.h == 0 then return end
    
    local is_ass = false
    local track_list = mp.get_property_native("track-list")
    
    -- Check if the currently selected subtitle is ASS/SSA
    if track_list then
        for _, track in ipairs(track_list) do
            if track.type == "sub" and track.selected then
                if track.codec == "ass" or track.codec == "ssa" then
                    is_ass = true
                end
                break
            end
        end
    end

    if is_ass then
        -- ASS/SSA format dictates its own styling and scaling mathematics.
        -- We reset the scale property so we don't destroy the layout.
        mp.set_property_number("sub-scale", 1.0)
    else
        -- For standard text subtitles (like .srt), apply dynamic scaling.
        local new_scale = base_scale
        
        -- If the window is smaller than the base height, we increase the scale 
        -- to prevent the text from becoming tiny and unreadable.
        if dim.h < base_height then
            new_scale = base_scale * (base_height / dim.h)
        end
        
        mp.set_property_number("sub-scale", new_scale)
    end
end

-- Re-calculate whenever the window is resized or a new subtitle track is selected
mp.observe_property("osd-dimensions", "native", update_scale)
mp.observe_property("track-list", "native", update_scale)