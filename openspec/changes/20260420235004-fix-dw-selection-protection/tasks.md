## 1. State Machine Update

- [x] 1.1 In `make_mouse_handler`, set `FSM.DW_PROTECTED_SELECTION = true` when a non-shift click occurs inside an existing selection.
- [x] 1.2 Update the `up` event in `make_mouse_handler` to skip the `DW_CURSOR_LINE/WORD` update if `FSM.DW_PROTECTED_SELECTION` is true.
- [x] 1.3 Ensure `FSM.DW_PROTECTED_SELECTION` is reset to `false` at the end of the `up` event handler.

## 2. Verification

- [ ] 2.1 Test selecting multiple lines (top to bottom), then clicking MMB on a middle word. Verify full selection is saved.
- [ ] 2.2 Test selecting multiple lines (bottom to top), then clicking MMB on a middle word. Verify full selection is saved.
- [ ] 2.3 Verify that standard drag-selection still works and updates the cursor correctly on release.
