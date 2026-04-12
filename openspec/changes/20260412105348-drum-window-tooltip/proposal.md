## Why

In Drum Window Mode (`w`), there's currently no way to view the second subtitles (translations) if they are desynced by sentence alignment. Users need a contextual, unobtrusive way to read translations without losing their place or breaking the existing presentation and hit-testing logic.

## What Changes

- Add a new "Tooltip" OSD layer specifically for translations in Drum Window mode.
- Introduce an RMB (Right Mouse Button) trigger to show a contextual translation balloon for the hovered primary subtitle line.
- The tooltip will close automatically when the mouse is moved to a different subtitle line.
- Implement a Phase 2 "Hover Mode" config option (`mpv.conf`) to auto-display the tooltip without requiring a click.
- Enforce the tooltip to appear on the right side with a fixed width, employing a translucent background to naturally blend gracefully over wide English text.
- Introduce configuration options for tooltip styling and context depth (`dw_tooltip_font_size`, `dw_tooltip_context_lines`, `dw_tooltip_bg_opacity`, etc).

## Capabilities

### New Capabilities
- `drum-window-tooltip`: The contextual tooltip balloon displaying secondary subtitles in Drum Window mode.

### Modified Capabilities
- `lls-mouse-input`: The input subsystem requires minor modifications to support hover-state tracking and RMB binding for tooltip pinning.

## Impact

- **Code:** Appends a new independent render function and OSD overlay to `lls_core.lua` without mutating `dw_build_layout`.
- **APIs/Bindings:** Enhances mouse coordinate/hit testing state machine with new variables (`FSM.DW_TOOLTIP_LINE`, `FSM.DW_TOOLTIP_MODE`).
- **Dependencies:** None.
