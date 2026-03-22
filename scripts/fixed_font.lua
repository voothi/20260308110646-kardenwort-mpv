local mp = require 'mp'

-- ==========================================
-- SCRIPT SETTINGS
-- ==========================================
-- Base window height (e.g. 1080p).
-- When the window is smaller than this, subtitles will stop shrinking.
local base_height = 1080 

-- Your preferred size multiplier
local base_scale = 1.0  

-- Scaling strength (0.0 to 1.0)
-- 0.0 = Normal mpv behavior (shrinks perfectly with window)
-- 0.5 = Halfway (softer scaling, very readable, less wrapping)
-- 1.0 = Strict fixed size (stays exactly 1080p size, wraps heavily)
local scale_strength = 0.5
-- ==========================================
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
        -- Counteract native shrinking when window height is below base_height
        -- using the softer scaling formula
        local comp_scale = 1.0
        if dim.h < base_height then
            local perfect_comp = base_height / dim.h
            -- Interpolate between 1.0 (no compensation) and perfect_comp (full fixed size)
            comp_scale = 1.0 + (perfect_comp - 1.0) * scale_strength
        end
        mp.set_property_number("sub-scale", comp_scale * base_scale)
    end
end

-- Re-calculate whenever the window is resized or a new subtitle track is selected
mp.observe_property("osd-dimensions", "native", update_scale)
mp.observe_property("track-list", "native", update_scale)