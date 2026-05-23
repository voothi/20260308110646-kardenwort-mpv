-- =========================================================================
-- KARDENWORT Drum Window: Pure Helpers
-- No mpv dependencies; safe to require under test harnesses.
-- All inputs are passed explicitly so callers (main.lua / tests) control state.
-- =========================================================================

local M = {}

-- Visual height of a single wrapped line inside a subtitle entry.
function M.vline_height(opts)
    local wrap_mul = opts.dw_wrap_line_height_mul or opts.dw_line_height_mul
    return (opts.dw_font_size * wrap_mul) + (opts.dw_vsp or 0)
end

-- Drag threshold in px (clamped to non-negative).
function M.drag_threshold_px(opts)
    local threshold = tonumber(opts.dw_mouse_drag_threshold_px) or 5
    if threshold < 0 then return 0 end
    return threshold
end

-- Auto-scroll timer interval in seconds (clamped to a positive default).
function M.auto_scroll_interval(opts)
    local interval = tonumber(opts.dw_mouse_auto_scroll_interval) or 0.05
    if interval <= 0 then return 0.05 end
    return interval
end

-- Maximum allowed per-side edge-zone ratio so the scroll-neutral band in the
-- middle of the screen never collapses to zero.
M.EDGE_SCROLL_RATIO_MAX = 0.49

-- Clamped edge-zone ratio: [0, EDGE_SCROLL_RATIO_MAX].
function M.edge_scroll_ratio(opts)
    local r = tonumber(opts.dw_mouse_edge_scroll_ratio) or 0.15
    if r < 0 then return 0 end
    if r > M.EDGE_SCROLL_RATIO_MAX then return M.EDGE_SCROLL_RATIO_MAX end
    return r
end

-- True if (x,y) is far enough from (down_x, down_y) to count as a drag.
-- A nil down_* coordinate is treated as the current position (no motion yet).
function M.pointer_exceeded_drag_threshold(opts, down_x, down_y, x, y)
    local dx = math.abs(x - (down_x or x))
    local dy = math.abs(y - (down_y or y))
    local threshold = M.drag_threshold_px(opts)
    return (dx > threshold or dy > threshold)
end

-- Fallback word resolution: when the visual line under the cursor has no
-- selectable words, find the closest word in the same subtitle.
--   1) Among zones in target_sub_idx that have selectable words,
--      pick the one whose y_top is vertically closest to ref_y_top.
--   2) Within that zone, pick the word whose horizontal center is closest
--      to osd_x.
-- Returns the logical_idx of the chosen word, or nil if no candidate exists.
function M.resolve_neighbor_word(zones, target_sub_idx, ref_y_top, osd_x)
    local best_zone = nil
    local best_dy = math.huge
    for _, z in ipairs(zones) do
        if z.sub_idx == target_sub_idx and z.words and #z.words > 0 then
            local dy = math.abs((z.y_top or 0) - ref_y_top)
            if dy < best_dy then
                best_dy = dy
                best_zone = z
            end
        end
    end
    if not best_zone then return nil end

    local rel_x = osd_x - (best_zone.x_start or 0)
    local best_word = nil
    local best_dx = math.huge
    for _, word in ipairs(best_zone.words) do
        local center = (word.x_offset or 0) + (word.width or 0) / 2
        local dx = math.abs(rel_x - center)
        if dx < best_dx then
            best_dx = dx
            best_word = word
        end
    end

    return best_word and best_word.logical_idx or nil
end

return M
