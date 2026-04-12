# Proposal: Fix Disappearing Subtitle Frame in Drum Mode C During Search

## Problem
In **Drum Mode C**, subtitles are rendered using an OSD overlay (`drum_osd`). Users have reported that when the Search UI (`Ctrl+f`) is activated while in this mode, the "dark frame" (background box) around the subtitles disappears, leaving only the text. This reduces readability and breaks the visual consistency of the "Black Frame" aesthetic.

The issue does not occur in normal mode because standard subtitles use `sub-border-style`, which remains unaffected.

## Cause
The root cause is the `manage_ui_border_override` function in `lls_core.lua`. To prevent the Search UI's text from having unwanted background boxes that clash with its custom-drawn interface, the script globally forces `osd-border-style` to `outline-and-shadow` whenever Search is active. Since Drum Mode subtitles also use the OSD system, they lose their `background-box` styling as well.

## Goal
Restore the dark subtitle frame in Drum Mode C even when the Search UI is active, while maintaining the "minimally invasive" approach.

## What Changes
- **ASS Alpha Management**: Instead of globally forcing `osd-border-style`, we will use the `{\\4a&HFF&}` ASS tag (shadow alpha) to hide the background box for specific OSD elements (Search UI, Drum Window) while leaving it visible for others (Drum Mode subtitles).
- **Cleanup**: Remove or disable the global `osd-border-style` override in `manage_ui_border_override`, and instead ensure all overlays explicitly define their background box transparency.
- **Consistency**: This ensures that even when Search is active, the subtitle frame remains visible because we no longer change the global border style.

## Capabilities

### Modified Capabilities
- `drum-mode-rendering`: Visual style persistence is achieved via per-event ASS styling rather than property toggling.

## Impact
- **Affected Code**: `scripts/lls_core.lua` (specifically `draw_search_ui`, `draw_dw`, `draw_drum`, and `manage_ui_border_override`).
- **Benefits**: Zero visual artifacts in the Search UI (it remains "light") and 100% persistence for subtitle frames.

