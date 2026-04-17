# Proposal: Fix Drum Window Sliding Window Clamping

## Objective
Ensure the Drum Window (Mode W) and Drum Mode (Mode C) always display a consistent, full range of subtitle lines when navigating near the start or end of a file.

## Context
When scrolling towards the end of a subtitle track in Drum Window mode, the number of visible lines currently decreases (e.g., from 15 to 8). This happens because the viewport is logically centered on the target subtitle index, and the range is calculated as `[center - half, center + half]`. When the center is near the file boundary, the range is truncated without shifting to fill the remaining slots with available preceding or succeeding subtitles. This causes a "shrinking block" effect and vertical shifting of the active line on the screen. This behavior is currently observed with mouse wheel scrolling and subtitle seeking ('d' key), while arrow keys handle it correctly by clamping the center index earlier.

## What Changes
Modify the layout generation logic in `lls_core.lua` to implement a "sliding window" boundary compensation. Instead of simple truncation, the window will shift its start or end index to maintain the maximum possible number of visible lines as defined by `Options.dw_lines_visible` (for Mode W) or `Options.drum_context_lines` (for Mode C).

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `subtitle-rendering`: Update the layout engine to maintain consistent line density and positioning at track boundaries in drum-style views.

## Impact
- **lls_core.lua**: Modification of `dw_build_layout` and `draw_drum` functions.
- **UI/UX**: Consistent visual experience when scrolling at the edges of the media.
- **Tooltips**: Improved reliability as more lines remain visible and interactive at file boundaries.
