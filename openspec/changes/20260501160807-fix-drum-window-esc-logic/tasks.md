## 1. Selection Boundary Hardening

- [x] 1.1 Update `get_dw_selection_bounds` in `lls_core.lua` to use `logical_cmp` for word index comparison.

## 2. Escape Logic Refactoring

- [x] 2.1 Refactor `cmd_dw_esc` in `lls_core.lua` to implement Stage 1: Clear Pink Set (`FSM.DW_CTRL_PENDING_SET`).
- [x] 2.2 Implement Stage 2 in `cmd_dw_esc`: Clear Yellow Range (if `get_dw_selection_bounds()` returns a range).
- [x] 2.3 Implement Stage 3 in `cmd_dw_esc`: Clear Yellow Pointer (`FSM.DW_CURSOR_WORD`).
- [x] 2.4 Ensure `cmd_dw_esc` Stage 3 also clears `DW_ANCHOR_LINE` and `DW_ANCHOR_WORD`.
- [x] 2.5 Ensure `cmd_dw_esc` Stage 3 synchronizes `DW_CURSOR_LINE` to `DW_ACTIVE_LINE`.
- [x] 2.6 Implement Stage 4 in `cmd_dw_esc`: Close the Drum Window if no selection states remain.

## 3. Verification

- [ ] 3.1 Verify single `Esc` clears Yellow Pointer and second `Esc` closes window.
- [ ] 3.2 Verify sequential clearing of Pink Set -> Yellow Range -> Yellow Pointer.
- [ ] 3.3 Verify behavior consistency in both Mode C and Mode W.
