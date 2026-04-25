# Tasks: Search Box Visibility Fix (OSD Styling)

## 1. Core Logic
- [x] Add `saved_osd_border_style` to FSM state
- [x] Implement `manage_ui_border_override(enable)` helper
- [x] Implement reference-aware check (only restore if all UI is closed)

## 2. UI Integration
- [x] Integrate override logic into `manage_search_bindings`
- [x] Integrate override logic into `cmd_toggle_drum_window`

## 3. Validation
- [x] Verify search text clarity with `osd-border-style=background-box` active
- [x] Verify correct restoration of user style on UI exit
- [x] Test concurrent UI scenarios (Search + Drum Window)
