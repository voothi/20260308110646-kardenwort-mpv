local mp = require 'mp'

-- ==========================================
-- SCRIPT SETTINGS
-- ==========================================
-- Base window height (e.g. 720p). 
-- When the window is smaller than this, subtitles will stop shrinking.
local base_height = 720 

-- Your preferred size multiplier
local base_scale = 1.0  
-- ==========================================

mp.observe_property("osd-dimensions", "native", function(name, dim)
    if not dim or dim.h == 0 then return end
    
    local new_scale = base_scale
    
    -- If the window is smaller than the base height, we increase the scale 
    -- to prevent the text from becoming tiny and unreadable.
    if dim.h < base_height then
        new_scale = base_scale * (base_height / dim.h)
    end
    
    -- If the window is larger than base_height (e.g. fullscreen 1080p),
    -- new_scale remains 1.0. This allows the text to naturally grow with the video.
    
    mp.set_property_number("sub-scale", new_scale)
end)