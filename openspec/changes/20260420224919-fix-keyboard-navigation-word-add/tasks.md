## 1. Export Path Hardening

- [ ] 1.1 Fix `nil` reference in `dw_anki_export_selection` by defining `local target_sub = subs[cl]` in the keyboard fallback block.
- [ ] 1.2 Initialize `term` properly in the fallback block to ensure it can be correctly populated from the word token.
- [ ] 1.3 Ensure `advanced_index` is correctly formatted in the fallback block using the `0:cw:1` pattern.
- [ ] 1.4 Validate that `time_pos` is grounded to the start of the target subtitle segment plus the 1ms epsilon in the fallback path.

## 2. Cursor State Synchronization

- [ ] 2.1 Refactor `cmd_dw_line_move` to find the first valid logical word index of the target line instead of defaulting to 1.
- [ ] 2.2 Implement a "safe-empty" check in `cmd_dw_line_move` to set `FSM.DW_CURSOR_WORD` to -1 if no words are found on a line.
- [ ] 2.3 Verify `cmd_dw_toggle_pink` uses `FSM.DW_CURSOR_WORD` correctly when `was_mouse` is false.

## 3. UI and Visual Feedback

- [ ] 3.1 Add explicit `dw_osd:update()` call at the end of the `cmd_dw_toggle_pink` single-word fallback to ensure immediate pink highlight feedback.
- [ ] 3.2 Verify that `show_osd` messages for Anki saves are triggered correctly in the keyboard-run path.

## 4. Verification

- [ ] 4.1 Test 't' key after using UP/DOWN arrows on lines with and without words.
- [ ] 4.2 Test 'r' key (add word) after arrow navigation without any mouse interaction.
- [ ] 4.3 Verify that Middle Mouse Button still works as expected and doesn't collide with the new fallback logic.
