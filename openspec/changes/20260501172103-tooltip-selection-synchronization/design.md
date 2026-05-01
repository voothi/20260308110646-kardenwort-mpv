## Context
Currently, the Drum Window (Mode W) translation tooltip (E) is a non-interactive OSD overlay. While it displays the secondary subtitles (Russian), users cannot interact with it. In contrast, the Drum Mode (Mode C) allows interaction with both primary and secondary tracks because they share the same hit-zone storage and dispatcher. This design aims to bridge this gap by introducing hit-zone detection to the tooltip.

## Goals / Non-Goals

**Goals:**
- Enable word-level mouse interaction in the translation tooltip.
- Synchronize selection in the tooltip with the primary Drum Window text.
- Maintain O(1) rendering performance.
- Support all existing selection modes (single click, shift-select, drag).

**Non-Goals:**
- Implementing separate cursor states for primary and secondary tracks (they should remain synchronized).
- Changing the visual layout of the tooltip.

## Decisions

### 1. Unified Hit-Zone Storage
Introduce `FSM.DW_TOOLTIP_HIT_ZONES` to store the visual coordinates of words in the tooltip. This separation from the main window's hit zones prevents collision confusion and allows for simpler coordinate mapping.

### 2. Rendering-Integrated Hit-Zone Population
Update `draw_dw_tooltip` to calculate word positions during the layout phase. 
- **Vertical Alignment**: Calculate the Y offset for each visual line based on the centered `final_y` and `block_height`.
- **Horizontal Alignment**: Since the tooltip uses `an6` (middle-right) at `X=1800`, the X-start for each line is derived as `1800 - line_width`.
- **Caching**: Hit zones will be stored in `DW_TOOLTIP_DRAW_CACHE` to avoid re-calculation during static frames.

### 3. Coordinate Mapping
The hit-test function will use `dw_get_mouse_osd()` to retrieve aspect-ratio-corrected coordinates. The `dw_tooltip_hit_test` function will perform a simple linear scan through the active tooltip hit zones.

### 4. Integration with `lls_hit_test_all`
The master dispatcher `lls_hit_test_all` will be modified to prioritize the tooltip hit-test when the tooltip is visible. If a hit is detected, it will return the secondary track index and word index, which the existing mouse handler will then use to update the global state.

## Risks / Trade-offs

- **Hit Zone Density**: If a tooltip contains a large amount of text (e.g., many context lines), scanning many hit zones might impact performance. However, given the tooltip's size constraints (1400px width, limited lines), the number of zones will remain small enough for O(N) scanning to be negligible.
- **Vertical Jitter**: If the tooltip shifts vertically due to automatic centering, hit testing must remain synchronized with the current render. Using the cached hit zones ensures they always match the visible text.
