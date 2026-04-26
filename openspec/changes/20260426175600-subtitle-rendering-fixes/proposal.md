# Proposal: Subtitle Rendering and Interactivity Fixes

## Problem Statement

A recent audit has identified several regressions and UX issues in the subtitle rendering and interactivity engine:

1.  **Manual Positioning Violation**: The `tick_drum` function contains logic that automatically offsets the secondary subtitle position if it is located in the bottom half of the screen. This violates the `subtitle-rendering-spec`, which mandates that subtitle positions should be controlled purely manually by the user without script interference.
2.  **Cyrillic Hit-Testing Inaccuracy**: The hit-testing logic for OSD-based word selection relies on a width heuristic (`dw_get_str_width`) that does not accurately reflect the visual width of Cyrillic characters in proportional fonts (like Inter). This causes mouse clicks and tooltips to be offset or misaligned for Russian text.
3.  **UX Conflict on Double-Click**: Double-clicking a word in OSD mode is intended for seeking, but the current implementation can lead to unwanted UI state transitions (like the Drum Window appearing) that obstruct the view.
4.  **Visibility Dependency**: Drum Mode `c` rendering is currently gated by the native subtitle visibility state (`sub-visibility`). This prevents users from using the custom OSD rendering while native subtitles are hidden, which is a common use case for active listening practice.

## Proposed Changes

### 1. Restore Manual Positioning
Remove the `auto_offset` calculation and application in `tick_drum`. This ensures that the positions set via `r/t` (primary) and `R/T` (secondary) are respected exactly as requested by the user, regardless of their value.

### 2. Refine Hit-Testing Precision
Update `calculate_osd_line_meta` and `dw_get_str_width` to ensure width calculations are purely character-aware and use refined heuristics for proportional fonts. This will involve verifying that byte-length is never used as a proxy for character count or visual width.

### 3. Decouple OSD Visibility from Native State
Modify the rendering triggers in `master_tick` so that Drum Mode `c` can render even if native subtitle visibility is set to `false`. This allows for "custom-only" subtitle rendering.

### 4. Guard Double-Click Interaction
Ensure `cmd_dw_double_click` focuses exclusively on seeking to the word's timestamp and updating the selection state, without triggering transitions to the full Drum Window (Mode W) unless explicitly requested.

## Goals

*   [ ] Full compliance with `subtitle-rendering-spec` regarding manual positioning.
*   [ ] Precise mouse-word alignment for Cyrillic text in OSD mode.
*   [ ] Independent visibility control for Custom OSD rendering.
*   [ ] Smoother interaction flow when using the one-line OSD view.
