# Design: Tooltip Flicker Stabilization

## Overview
We will implement two layers of stabilization to address the flickering:
1. **OSD Update Guarding**: Only call `update()` if the generated ASS content has changed.
2. **Y-Position Determinism**: Round the calculated line center coordinates to the nearest pixel to avoid floating-point jitter in cache keys and positioning.

## Detailed Changes

### 1. `dw_tooltip_mouse_update`
Modify the update loop to check the new ASS string against `dw_tooltip_osd.data`.

```lua
local new_ass = draw_dw_tooltip(subs, target_l, target_y)
if new_ass ~= dw_tooltip_osd.data then
    FSM.DW_TOOLTIP_LINE = target_l
    dw_tooltip_osd.data = new_ass
    dw_tooltip_osd:update()
end
```

### 2. `draw_dw` and `get_tooltip_line_y`
Ensure that the Y-positions stored in `FSM.DW_LINE_Y_MAP` are rounded.

```lua
-- In draw_dw
FSM.DW_LINE_Y_MAP[i] = math.floor(current_y + (entry.height / 2) + 0.5)
```

### 3. Cache Refinement
In `draw_dw_tooltip`, the `osd_y` key should also be rounded to ensure that small mouse jitters (if `fallback_y` is used) don't invalidate the cache unnecessarily.

## Impact
- **Performance**: Significant reduction in OSD processing on every master tick.
- **Visuals**: Tooltip will remain perfectly still if the mouse is still or moving within the same snap-threshold.
- **Consistency**: Parity between OSD and DW rendering stability.
