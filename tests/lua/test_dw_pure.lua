-- =========================================================================
-- Pure-Lua unit tests for scripts/kardenwort/dw_pure.lua
-- Driven from pytest (tests/unit/test_dw_pure_lua_harness.py) via subprocess.
-- Exits 0 on success, 1 on any assertion failure; prints PASS/FAIL summary.
-- =========================================================================

package.path = "scripts/kardenwort/?.lua;" .. package.path
local DW = require "dw_pure"

local failed = 0
local total = 0

local function eq(name, actual, expected)
    total = total + 1
    if actual ~= expected then
        failed = failed + 1
        io.write(string.format("FAIL %s: expected %s, got %s\n",
            name, tostring(expected), tostring(actual)))
    end
end

local function near(name, actual, expected, eps)
    total = total + 1
    eps = eps or 1e-9
    if math.abs(actual - expected) > eps then
        failed = failed + 1
        io.write(string.format("FAIL %s: expected ~%s, got %s\n",
            name, tostring(expected), tostring(actual)))
    end
end

-- ---------------------------------------------------------------------------
-- vline_height
-- ---------------------------------------------------------------------------

near("vline_height: uses wrap_mul when present",
    DW.vline_height({dw_font_size = 40, dw_wrap_line_height_mul = 1.1, dw_line_height_mul = 0.9, dw_vsp = 0}),
    44.0)

near("vline_height: falls back to line_height_mul when wrap missing",
    DW.vline_height({dw_font_size = 40, dw_line_height_mul = 0.9, dw_vsp = 0}),
    36.0)

near("vline_height: adds dw_vsp",
    DW.vline_height({dw_font_size = 40, dw_wrap_line_height_mul = 1.0, dw_vsp = 5}),
    45.0)

near("vline_height: tolerates missing vsp",
    DW.vline_height({dw_font_size = 40, dw_wrap_line_height_mul = 1.0}),
    40.0)

-- ---------------------------------------------------------------------------
-- drag_threshold_px
-- ---------------------------------------------------------------------------

eq("drag_threshold_px: default is 5", DW.drag_threshold_px({}), 5)
eq("drag_threshold_px: custom value", DW.drag_threshold_px({dw_mouse_drag_threshold_px = 8}), 8)
eq("drag_threshold_px: negative clamped to 0", DW.drag_threshold_px({dw_mouse_drag_threshold_px = -3}), 0)
eq("drag_threshold_px: garbage string falls back to 5", DW.drag_threshold_px({dw_mouse_drag_threshold_px = "x"}), 5)

-- ---------------------------------------------------------------------------
-- auto_scroll_interval
-- ---------------------------------------------------------------------------

near("auto_scroll_interval: default", DW.auto_scroll_interval({}), 0.05)
near("auto_scroll_interval: custom",
    DW.auto_scroll_interval({dw_mouse_auto_scroll_interval = 0.1}), 0.1)
near("auto_scroll_interval: zero falls back to default",
    DW.auto_scroll_interval({dw_mouse_auto_scroll_interval = 0}), 0.05)
near("auto_scroll_interval: negative falls back to default",
    DW.auto_scroll_interval({dw_mouse_auto_scroll_interval = -1}), 0.05)

-- ---------------------------------------------------------------------------
-- edge_scroll_ratio
-- ---------------------------------------------------------------------------

near("edge_scroll_ratio: default", DW.edge_scroll_ratio({}), 0.15)
near("edge_scroll_ratio: custom",
    DW.edge_scroll_ratio({dw_mouse_edge_scroll_ratio = 0.2}), 0.2)
near("edge_scroll_ratio: negative clamped to 0",
    DW.edge_scroll_ratio({dw_mouse_edge_scroll_ratio = -0.1}), 0)
near("edge_scroll_ratio: too large clamped to MAX",
    DW.edge_scroll_ratio({dw_mouse_edge_scroll_ratio = 0.9}), DW.EDGE_SCROLL_RATIO_MAX)
eq("edge_scroll_ratio: MAX is documented constant", DW.EDGE_SCROLL_RATIO_MAX, 0.49)

-- ---------------------------------------------------------------------------
-- pointer_exceeded_drag_threshold
-- ---------------------------------------------------------------------------

local opts5 = {dw_mouse_drag_threshold_px = 5}

eq("drag threshold: same point => false",
    DW.pointer_exceeded_drag_threshold(opts5, 100, 100, 100, 100), false)
eq("drag threshold: dx exactly threshold => false (strict >)",
    DW.pointer_exceeded_drag_threshold(opts5, 100, 100, 105, 100), false)
eq("drag threshold: dx beyond threshold => true",
    DW.pointer_exceeded_drag_threshold(opts5, 100, 100, 106, 100), true)
eq("drag threshold: dy beyond threshold => true",
    DW.pointer_exceeded_drag_threshold(opts5, 100, 100, 100, 110), true)
eq("drag threshold: nil down_x falls back to current => false",
    DW.pointer_exceeded_drag_threshold(opts5, nil, nil, 100, 100), false)
eq("drag threshold: zero threshold catches 1px motion",
    DW.pointer_exceeded_drag_threshold({dw_mouse_drag_threshold_px = 0}, 100, 100, 101, 100), true)

-- ---------------------------------------------------------------------------
-- resolve_neighbor_word (the bug fix)
-- ---------------------------------------------------------------------------

-- Setup: subtitle 7 has three visual lines.
-- Line A (y=100): logical words at x=10,30,50
-- Line B (y=200): no words (spacer-only line - this is the empty best_zone case)
-- Line C (y=300): logical words at x=10,30,50
local zones = {
    {sub_idx = 6, y_top = 0,   x_start = 0,
        words = {{logical_idx = 99, x_offset = 0, width = 20}}},
    {sub_idx = 7, y_top = 100, x_start = 0,
        words = {
            {logical_idx = 1, x_offset = 10, width = 10},
            {logical_idx = 2, x_offset = 30, width = 10},
            {logical_idx = 3, x_offset = 50, width = 10},
        }},
    {sub_idx = 7, y_top = 200, x_start = 0, words = {}}, -- "empty" line; the failing case
    {sub_idx = 7, y_top = 300, x_start = 0,
        words = {
            {logical_idx = 11, x_offset = 10, width = 10},
            {logical_idx = 12, x_offset = 30, width = 10},
            {logical_idx = 13, x_offset = 50, width = 10},
        }},
    {sub_idx = 8, y_top = 400, x_start = 0,
        words = {{logical_idx = 77, x_offset = 0, width = 20}}},
}

-- Empty line at y=200 is equidistant from line A (dy=100) and line C (dy=100).
-- Ties broken by iteration order: first match wins, so line A is picked.
-- Within line A, the word horizontally closest to osd_x is returned.
eq("resolve_neighbor_word: picks closest word horizontally in nearest zone",
    DW.resolve_neighbor_word(zones, 7, 200, 35), 2)
eq("resolve_neighbor_word: leftmost when osd_x is far left",
    DW.resolve_neighbor_word(zones, 7, 200, 0), 1)
eq("resolve_neighbor_word: rightmost when osd_x is far right",
    DW.resolve_neighbor_word(zones, 7, 200, 1000), 3)

-- When the empty line is closer to line C (e.g. ref_y_top=290), line C wins.
eq("resolve_neighbor_word: vertical proximity wins (line C)",
    DW.resolve_neighbor_word(zones, 7, 290, 35), 12)

-- Cross-subtitle isolation: ref sub_idx=7, but only sub_idx=99 zones exist.
eq("resolve_neighbor_word: returns nil when no same-sub candidates",
    DW.resolve_neighbor_word(zones, 99, 200, 35), nil)

-- Regression guard for the old bug: if the implementation iterates words in
-- a zone without varying dist per word, it would return the LAST word of the
-- nearest zone (logical_idx = 3) instead of the horizontally-closest (logical_idx = 2).
local guard = DW.resolve_neighbor_word(zones, 7, 200, 35)
if guard == 3 then
    failed = failed + 1
    total = total + 1
    io.write("FAIL resolve_neighbor_word: returned LAST word of zone (the old bug);"
        .. " expected horizontally-closest word\n")
end

-- ---------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------

if failed == 0 then
    io.write(string.format("PASS %d/%d\n", total, total))
    os.exit(0)
else
    io.write(string.format("FAIL %d/%d (%d failures)\n", total - failed, total, failed))
    os.exit(1)
end
