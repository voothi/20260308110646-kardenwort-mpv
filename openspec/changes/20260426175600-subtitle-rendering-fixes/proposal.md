# Proposal: Subtitle Rendering and Interactivity Fixes

## Problem Statement

A recent audit has identified several regressions and UX issues in the subtitle rendering and interactivity engine:

1.  **Safety-Aware Positioning**: Subtitles currently overlap when positioned close together in the bottom half of the screen if manual control is too permissive. The `tick_drum` logic needs to ensure a safety gap to maintain legibility while still allowing user control via relative adjustments.
2.  **Cyrillic Hit-Testing Inaccuracy**: The hit-testing logic for OSD-based word selection relies on a width heuristic (`dw_get_str_width`) that does not accurately reflect the visual width of Cyrillic characters in proportional fonts (like Inter). This causes mouse clicks and tooltips to be offset or misaligned for Russian text.
3.  **Double-Click "Echo" Interaction**: Double-clicking a word in OSD mode centers the subtitle and seeks the video. However, the dragging state and lack of an interaction shield for the sync engine cause an "echo" selection at the new position.
4.  **Selection Persistence**: There is a requirement that double-clicking a subtitle to seek should clear any existing word selection to prevent misleading highlights in the new visual context.
5.  **Visibility Dependency**: Drum Mode `c` rendering is currently gated by the native subtitle visibility state (`sub-visibility`).

## Proposed Changes

### 1. Restore Safety-Aware Positioning
Maintain the `auto_offset` calculation in `tick_drum`. This ensures that tracks do not overlap when both are in the bottom half of the screen, while still allowing the user to adjust the relative positions within the safety boundaries.

### 2. Refine Hit-Testing Precision
Update `calculate_osd_line_meta` and `dw_get_str_width` to ensure width calculations are purely character-aware and use refined heuristics for proportional fonts.

### 3. Decouple OSD Visibility from Native State
Modify the rendering triggers in `master_tick` so that Drum Mode `c` can render even if native subtitle visibility is set to `false`. This allows for "custom-only" subtitle rendering.

### 4. Guard Double-Click Interaction
Ensure `cmd_dw_double_click` focuses exclusively on seeking and selection updates without triggering transitions to the full Drum Window (Mode W) unless explicitly requested.

## Goals

*   [x] Safety-aware positioning to prevent track overlap.
*   [ ] Precise mouse-word alignment for Cyrillic text in OSD mode.
*   [ ] Independent visibility control for Custom OSD rendering.
*   [ ] Smoother interaction flow when using the one-line OSD view.
