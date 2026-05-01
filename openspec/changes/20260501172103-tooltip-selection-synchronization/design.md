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

## Tooltip Interaction Architecture

### 1. Unified Hit-Zone Pipeline (Surgical Model)
Interaction in the Drum Window tooltip follows a **Surgical Model**. Hit zones are populated during the `draw_dw_tooltip` phase and cached in `DW_TOOLTIP_DRAW_CACHE`.
- **Granularity**: Hit zones are created at the word level within visual lines.
- **Occlusion**: The tooltip (`z=25`) has priority over the Drum Window (`z=20`). Clicks land on tooltip words first.
- **Pass-Through**: Clicks in "gaps" (between words or lines) pass through to the background Drum Window text, maintaining high-precision background interaction even while the tooltip is visible.

### 2. Stability and Flicker Prevention
To ensure a premium UX, the rendering pipeline implements two suppression mechanisms:
- **Click-Blink Suppression**: The `is_tooltip_hit` check in the mouse handler prevents the tooltip from being dismissed (cleared) when clicking directly on it for selection.
- **Sticky Quick-View**: During "Quick-View" (RMB-hold), the tooltip enters a "sticky" state. It ignores "nil" hit-tests (gaps) to prevent flickering, only updating its content when the cursor lands on a distinct subtitle line.

### 3. Coordinate Mapping (Right-Aligned an6)
Coordinates are mapped relative to the `X=1800` anchor:
- `x_start = 1800 - visual_line_width`
- `y_top/y_bottom` calculated from the aggregate block height and vertical centering logic.

### 4. Caching and Performance
- `FSM.DW_TOOLTIP_HIT_ZONES` is stored in the draw cache.
- $O(1)$ restoration of interaction data when serving from cache to prevent layout re-calculation overhead.

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
