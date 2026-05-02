# Tasks: Calibrate Drum Window Navigation and Visibility

## 1. Highlighting Refinement

- [x] 1.1 Update `format_highlighted_word` in `scripts/lls_core.lua` to accept an `is_manual` parameter.
- [x] 1.2 Modify `format_highlighted_word` logic to force full-token highlighting if `is_manual` or `is_phrase` is true.
- [x] 1.3 Update the rendering loop in `draw_dw` to determine `is_manual` based on token priority (1 or 2) and pass it to the formatting engine.

## 2. Navigation Refinement

- [x] 2.1 Update `cmd_dw_word_move` in `scripts/lls_core.lua` to call `dw_ensure_visible(FSM.DW_CURSOR_LINE, false)` after updating the cursor position.
- [x] 2.2 Verify that horizontal line jumping correctly triggers the viewport follow-check.

## 3. Verification and Sync

- [x] 3.1 Perform physical MPV testing to confirm punctuation focus visibility.
- [x] 3.2 Verify that the "Surgical" look is preserved for automated database matches (Priority 3).
- [x] 3.3 Confirm that all changes are synchronized with the `openspec` delta requirements.
- [x] 3.4 Verify that LEFT/RIGHT line-wrapping correctly lands on the start/end of the adjacent line.
