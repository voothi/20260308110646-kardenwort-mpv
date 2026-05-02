## 1. Implement Priority Logic in Drum Window Copy

- [x] 1.1 Locate `cmd_dw_copy` in `scripts/lls_core.lua`.
- [x] 1.2 Define a `has_selection` flag based on `FSM.DW_ANCHOR_LINE` and `FSM.DW_CURSOR_WORD`.
- [x] 1.3 Update the logic to only attempt `get_copy_context_text` if `has_selection` is false.
- [x] 1.4 Ensure that if `final_text` is empty (no context or context failed), it proceeds to standard selection copy.

## 2. Implement Priority Logic in Global Copy

- [x] 2.1 Locate `cmd_copy_sub` in `scripts/lls_core.lua`.
- [x] 2.2 Add a selection check to `cmd_copy_sub` that respects `FSM.DW_CURSOR_WORD` and `FSM.DW_ANCHOR_LINE` if the Drum Window is active.
- [x] 2.3 Reorder the context copy block to be an `elseif` after the selection check.
- [x] 2.4 Verify that `prepare_export_text` is called with the correct `params` when a selection is detected in `cmd_copy_sub`.

## 3. Verification

- [x] 3.1 Verify that with Context Copy ON, clicking a word in the Drum Window and pressing Copy copies ONLY that word.
- [x] 3.2 Verify that with Context Copy ON, selecting a range in the Drum Window and pressing Copy copies ONLY that range.
- [x] 3.3 Verify that with Context Copy ON and NO selection, pressing Copy copies the context.
- [x] 3.4 Verify that pressing `Esc` clear selections and allows the next Copy to use context.
