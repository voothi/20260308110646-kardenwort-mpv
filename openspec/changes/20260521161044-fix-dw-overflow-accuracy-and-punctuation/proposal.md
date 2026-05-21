## Why

The Drum Window (DW) mode previously suffered from layout overflow issues under low resolution or large font/multi-line wrapping, rendering top/bottom lines off-screen. Click-accuracy drift in DW mode caused mouse selections to target incorrect lines on lower subtitles due to vertical calibration drift between the hit-test model and ASS renderer. Additionally, a missing local variable regression caused translation tooltips to crash during rendering, and punctuation marks could not be selected in Drum Mode (DM).

## What Changes

- **Dynamic Layout Clamping**: Centers the focused visual subtitle line and clamps the rendering block bounds within a configurable safe-area padding (`dw_edge_margin` defaulting to 24px) when the total height overflows the OSD canvas (1080p).
- **Decoupled Wrap Line Height**: Decouples intra-subtitle line height from inter-subtitle spacing using `dw_wrap_line_height_mul` (defaulting to 1.05), providing adequate clearance for descender characters (e.g., `g`, `j`, `y`) within wrapped text lines.
- **Unified Hit Zone Caching**: Populates and caches `FSM.DW_HIT_ZONES` during the drawing phase (`draw_dw`) and aligns the hit tester (`dw_hit_test`) to dispatch mouse clicks directly against these actual visual positions, achieving 100% click accuracy.
- **Unified Single-Block DW Rendering**: Keeps Drum Window output as one cohesive ASS dialogue block (`\an5` anchor) while preserving dynamic clamping math, avoiding fragmented per-line frame artifacts.
- **Tooltip Variable Restoration**: Restores the missing local font variables `fs` and `line_height` in `draw_dw_tooltip` to resolve the `string.format(nil)` crash.
- **Unified Punctuation Interactivity**: Removes the `is_word` filter guard in Drum Mode (`draw_drum`), allowing sentence-ending punctuation (e.g., `.`, `?`, `!`) to be interactive and highlightable, matching DW mode capabilities.

## Capabilities

### New Capabilities
*None*

### Modified Capabilities
- `drum-window`: Introduce dynamic boundary clamping, customizable `dw_edge_margin`, and decoupled `dw_wrap_line_height_mul`.
- `drum-window-tooltip`: Restore font and line height tracking to prevent OSD formatting exceptions.
- `drum-context`: Remove the `is_word` restriction for token interaction in Drum Mode (DM) to support punctuation selection.

## Impact

- **Affected Code**: `scripts/kardenwort/main.lua`
- **Affected Tests**: `tests/acceptance/test_20260521133435_dw_top_alignment.py` and regression suites.
