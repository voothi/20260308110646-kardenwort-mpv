## 1. Preparation

- [ ] 1.1 Add `DW_TOOLTIP_LOCKED_LINE = -1` to the `FSM` table in `scripts/lls_core.lua` to track the suppressed line.

## 2. Implement Mouse Suppression Logic

- [ ] 2.1 Update the `make_mouse_handler` factory in `scripts/lls_core.lua` to dismiss any active tooltip and set the `DW_TOOLTIP_LOCKED_LINE` lock during the `down` event.
- [ ] 2.2 Ensure the lock is preserved during `up` events to support the "sticky" suppression behavior.

## 3. Implement Tooltip Guard Logic

- [ ] 3.1 Modify `dw_tooltip_mouse_update` in `scripts/lls_core.lua` to skip tooltip rendering if `DW_MOUSE_DRAGGING` is active or if the mouse focus matches the `DW_TOOLTIP_LOCKED_LINE`.
- [ ] 3.2 Add logic in `dw_tooltip_mouse_update` to release the lock (`DW_TOOLTIP_LOCKED_LINE = -1`) once the focus changes to a new line or is lost, provided the mouse is not currently dragging.

## 4. Verification

- [ ] 4.1 Verify that Right-Click (pin) followed by Left-Click instantly hides the pinned hint.
- [ ] 4.2 Verify that clicking and dragging the Left-Mouse-Button across multiple lines keeps all tooltips suppressed until release.
- [ ] 4.3 Verify that after releasing a drag on a specific line, no tooltip appears for that line until the mouse focus moves to a different line.
