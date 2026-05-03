## 1. Interaction Hardening (lls_core.lua)

- [ ] 1.1 In `dw_tooltip_mouse_update`, add `FSM.DW_TOOLTIP_HIT_ZONES = nil` to the "Dragging/Locked" suppression branch (Line 4111).
- [ ] 1.2 In `dw_tooltip_mouse_update`, add `FSM.DW_TOOLTIP_HIT_ZONES = nil` to the "Mouse-Out" dismissal branch (Line 4162).
- [ ] 1.3 In `dw_tooltip_mouse_update`, add `FSM.DW_TOOLTIP_HIT_ZONES = nil` to the "Keyboard Force" dismissal branch (Line 4102).
- [ ] 1.4 Update `dw_tooltip_hit_test` to return `nil, nil` if `FSM.DW_TOOLTIP_LINE == -1`.

## 2. Verification & Calibration Test

- [ ] 2.1 Enable Drum Window (`w`) and Tooltip (`e`).
- [ ] 2.2 Hover over a line to show the tooltip, then move mouse away.
- [ ] 2.3 Verify that clicking/hovering on the right side of the Drum Window still works perfectly (no ghost interception).
- [ ] 2.4 Verify that selection (dragging) in the Drum Window is not interrupted by ghost tooltip zones.
