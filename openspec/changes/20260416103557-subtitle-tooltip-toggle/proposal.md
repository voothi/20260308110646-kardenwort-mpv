## Why

Users need the ability to toggle the current subtitle's tooltip using the keyboard (specifically the 'e' / 'у' keys on EN/RU layouts). Relying solely on the mouse for this interaction breaks keyboard-driven workflows and compromises accessibility.

## What Changes

- Bind 'e' and 'у' (cyrillic) to a new action that toggles the display of the tooltip for the current subtitle on screen.
- Implement logic to handle the visibility state of the tooltip via keyboard trigger, without requiring a mouse hover.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `drum-window-tooltip`: The tooltip specification will be updated to include keyboard-driven toggling ('e' / 'у' keys), extending the previous hover-only interaction model.

## Impact

- Input bindings for mpv (keybindings).
- Tooltip rendering state logic.
- Potential updates to `lls_core.lua` or related modules to handle keyboard interactions for tooltips.
