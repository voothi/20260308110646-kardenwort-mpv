# Proposal: Fix Disappearing Subtitle Frame in Drum Mode C During Search

## Problem
In **Drum Mode C**, subtitles are rendered using an OSD overlay (`drum_osd`). Users have reported that when the Search UI (`Ctrl+f`) is activated while in this mode, the "dark frame" (background box) around the subtitles disappears, leaving only the text. This reduces readability and breaks the visual consistency of the "Black Frame" aesthetic.

The issue does not occur in normal mode because standard subtitles use `sub-border-style`, which remains unaffected.

## Cause
The root cause is the `manage_ui_border_override` function in `lls_core.lua`. To prevent the Search UI's text from having unwanted background boxes that clash with its custom-drawn interface, the script globally forces `osd-border-style` to `outline-and-shadow` whenever Search is active. Since Drum Mode subtitles also use the OSD system, they lose their `background-box` styling as well.

## Goal
Restore the dark subtitle frame in Drum Mode C even when the Search UI is active, while maintaining the "minimally invasive" approach.

## What Changes
- **Logic Refinement**: Modify `manage_ui_border_override` to take the current `DRUM` state into account.
- **Priority Shift**: If Drum Mode is active, the global `osd-border-style` will not be overridden to `outline-and-shadow`. This ensures subtitles retain their frame at the cost of the Search UI showing its default background boxes (which is preferable to losing subtitles context).
- **Transient State Handling**: Ensure that if Drum Mode is toggled or Search is closed/opened in various sequences, the style is correctly restored to the user's `mpv.conf` default.

## Capabilities

### Modified Capabilities
- `drum-mode-rendering`: The Drum Mode renderer will now have its visual style preserved during active search sessions by preventing global OSD style overrides when active.

## Impact
- **Affected Code**: `scripts/lls_core.lua` (specifically `manage_ui_border_override` and potentially the search toggle logic).
- **Side Effects**: The Search UI may show additional background boxes around its text *only when Drum Mode is active*. Given the "minimally invasive" requirement, this is the safest trade-off compared to complex manual box rendering.
