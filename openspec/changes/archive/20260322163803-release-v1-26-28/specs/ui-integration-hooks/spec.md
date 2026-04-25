# Spec: UI Integration Hooks

## Context
The override logic must be seamlessly integrated into the existing UI control functions.

## Requirements
- Integrate `manage_ui_border_override` into:
    - `manage_search_bindings` (Search HUD entry/exit).
    - `cmd_toggle_drum_window` (Drum Window toggle).
- Ensure the override is triggered *before* the first OSD update of the custom UI.

## Verification
- Verify that there is no "flicker" of the incorrect style when opening the search box.
- Confirm that both mouse and keyboard toggles for these UI elements trigger the override.
