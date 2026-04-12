## 1. Preparation

- [x] 1.1 Add `DW_TOOLTIP_LOCKED_LINE = -1` to the `FSM` table in `scripts/lls_core.lua` to track the suppressed line.

## 2. Implement Mouse Suppression Logic

- [x] 2.1 Update the `make_mouse_handler` factory in `scripts/lls_core.lua` to dismiss any active tooltip and set the `DW_TOOLTIP_LOCKED_LINE` lock during the `down` event.
- [x] 2.2 Re-set the suppression lock on the `up` event to ensure the line where a drag ends is also guarded.

## 3. Implement Tooltip Guard Logic

- [x] 3.1 Modify `dw_tooltip_mouse_update` in `scripts/lls_core.lua` to skip tooltip rendering if `DW_MOUSE_DRAGGING` is active or if the mouse focus matches the `DW_TOOLTIP_LOCKED_LINE`.
- [x] 3.2 Add logic in `dw_tooltip_mouse_update` to release the lock once focus moves to a different line.
- [x] 3.3 Ensure `cmd_dw_tooltip_pin` (RMB) clears the suppression lock to allow manual re-activation.

## 4. Verification

- [ ] 4.1 Verify that Right-Click (pin) followed by Left-Click instantly hides the pinned hint.
- [ ] 4.2 Verify that clicking and dragging the Left-Mouse-Button across multiple lines keeps all tooltips suppressed until release.
- [ ] 4.3 Verify that after releasing a drag on a specific line, no tooltip appears for that line until the mouse focus moves to a different line.
