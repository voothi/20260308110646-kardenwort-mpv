## 1. Core Logic Update

- [x] 1.1 Locate the `draw_dw` function in `scripts/lls_core.lua`.
- [x] 1.2 Extract the `ctrl_member` check from the `elseif l_idx` block and move it to the beginning of the word-formatting loop.
- [x] 1.3 Update the logical chain so that `ctrl_member` status takes priority over the `selected` range boolean.
- [x] 1.4 Ensure the `cl` (cursor line) and `cw` (cursor word) highlight is also subordinate to the `ctrl_member` state.

## 2. Verification

- [x] 2.1 Verify that Ctrl + LMB selected words maintain their muted yellow color even when hovered by the mouse.
- [x] 2.2 Verify that Ctrl + LMB selected words maintain their muted yellow color even when included in a larger drag-selection (vibrant yellow) range.
- [x] 2.3 Ensure standard selection and cursor highlights still work correctly for words *not* in the Ctrl-pending set.
