## 1. Export Path Hardening

- [x] 1.1 Fix `nil` reference in `dw_anki_export_selection` by defining `local target_sub = subs[cl]` in the keyboard fallback block.
- [x] 1.2 Initialize `term` properly in the fallback block to ensure it can be correctly populated from the word token.
- [x] 1.3 Ensure `advanced_index` is correctly formatted in the fallback block using the `0:cw:1` pattern.
- [x] 1.4 Validate that `time_pos` is grounded to the start of the target subtitle segment plus the 1ms epsilon in the fallback path.

## 2. Cursor State Synchronization

- [x] 2.1 Implement `get_first_valid_word_idx(sub)` helper function to scan tokens for the first logical word index.
- [x] 2.2 Update `cmd_dw_line_move` to use the helper function for `FSM.DW_CURSOR_WORD` assignment.
- [x] 2.3 Implement the shift-logic check in `cmd_dw_line_move` to preserve existing word cursors during selection expansion.
- [x] 2.4 Implement a "safe-empty" return of `-1` if no words are found on a line to prevent invalid index propagation.

## 3. UI and Visual Feedback

- [x] 3.1 Verify that `show_osd` messages for Anki saves are triggered correctly in the keyboard-run path.
- [x] 3.2 Confirm that `ctrl_toggle_word` correctly refreshes the OSD once valid indices are provided by the improved navigation logic.

## 4. Verification

- [x] 4.1 Test 't' key after using UP/DOWN arrows on lines with and without words.
- [x] 4.2 Test 'r' key (add word) after arrow navigation without any mouse interaction.
- [x] 4.3 Verify that Middle Mouse Button still works as expected and doesn't collide with the new fallback logic.
