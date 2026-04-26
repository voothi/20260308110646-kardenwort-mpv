# Design: Subtitle Rendering and Interactivity Fixes

## Context

The current subtitle rendering engine implements "smart" features that sometimes conflict with manual user control or provide inaccurate interaction zones for non-Latin text. Specifically, automatic position adjustments and heuristic-based hit-testing for Cyrillic text are areas of friction.

## Goals / Non-Goals

**Goals:**
*   Restore 1:1 manual control for subtitle positioning.
*   Ensure accurate word-level hit-testing for Cyrillic text in OSD mode.
*   Allow Custom OSD rendering even when native subtitles are suppressed.
*   Prevent unwanted UI mode transitions during mouse interactions.

**Non-Goals:**
*   Implementing a full font-measurement engine (impossible in native mpv Lua without external dependencies).
*   Changing the core layout of the Drum Window (Mode W).

## Decisions

### 1. Safety-Aware Positioning
The auto-offset logic in `tick_drum` will be restored and maintained. When the secondary track is positioned in the bottom half of the screen, the system will calculate a safety offset based on the primary track's height to prevent overlap. This ensures legibility while still respecting the user's relative position adjustments.

### 2. Heuristic-Based Word Width Refinement
While we cannot measure fonts exactly, we can improve the heuristic in `dw_get_str_width` for proportional fonts. We will ensure that the loop always counts characters (not bytes) and apply a consistent width factor for Cyrillic characters that better matches the common `Inter` font metrics used in the project.

### 3. Drum Mode Visibility Override
In `master_tick`, the rendering decision for `pri_use_osd` and `sec_use_osd` will be updated. If `FSM.DRUM` is "ON", the tracks will be rendered to the OSD regardless of the `FSM.native_sub_vis` state. This allows the user to hide native subtitles while still seeing the interactive Drum Mode OSD.

### 4. Double-Click Contextual Guarding
The `cmd_dw_double_click` function will be updated to handle the distinction between "W" mode (Window) and "C" mode (OSD). In OSD mode, it will focus on seeking and selection updates without triggering the `cmd_toggle_drum_window()` function.

## Risks / Trade-offs

*   **Overlap Risk**: Removing auto-offset means tracks can overlap if the user positions them poorly. This is considered an acceptable trade-off for predictability and control.
*   **Heuristic Limitations**: Proportional width estimation remains a heuristic. Perfect word-click alignment is not guaranteed across all possible fonts, but will be significantly improved for the project's recommended fonts.
