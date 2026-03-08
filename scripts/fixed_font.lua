local mp = require 'mp'

-- ==========================================
-- SCRIPT SETTINGS
-- ==========================================
-- Base window height at which the font size is 1.0 (original size)
local base_height = 720 

-- Your preferred size multiplier
local base_scale = 1.0  
-- ==========================================

mp.observe_property("osd-dimensions", "native", function(name, dim)
    if not dim or dim.h == 0 then return end
    
    -- Calculate the new scale: the smaller the window, the larger the multiplier
    local new_scale = base_scale * (base_height / dim.h)
    
    -- Apply the absolute physical size to the subtitles
    mp.set_property_number("sub-scale", new_scale)
end)