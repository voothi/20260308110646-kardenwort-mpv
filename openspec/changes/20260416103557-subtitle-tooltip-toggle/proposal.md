## Why

Users need the ability to toggle the subtitle translation/context tooltip using the keyboard (specifically the 'e' / 'у' keys on EN/RU layouts). Relying solely on the mouse for this interaction breaks keyboard-driven workflows and compromises accessibility. It must be clarified that this behavior is specifically scoped to the Drum Window ('w' mode).

## What Changes

- Bind 'e' and 'у' (cyrillic) to a new action that toggles the display of the tooltip specifically when interacting with the Drum Window ('w' mode).
- Introduce configurable parameters in `mpv.conf` to easily assign or change the designated 'toggle' keys for this feature (e.g., `script-opts-append=drum_window-toggle_key=e`).
- Implement logic to handle the visibility state of the tooltip via keyboard trigger within the Drum Window.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `drum-window-tooltip`: The tooltip specification will be updated to include keyboard-driven toggling ('e' / 'у' keys), extending the previous hover-only interaction model.

## Impact

- Input bindings for mpv (keybindings).
- Tooltip rendering state logic.
- Potential updates to `lls_core.lua` or related modules to handle keyboard interactions for tooltips.
