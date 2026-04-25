## 1. Logic Implementation

- [ ] 1.1 Modify `cmd_dw_seek_delta` to only update `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD` when `FSM.BOOK_MODE` is OFF.
- [ ] 1.2 Verify that `DW_CURSOR_X` (sticky horizontal position) is not accidentally reset during seeking in Book Mode.

## 2. Verification and Testing

- [ ] 2.1 Verify pointer persistence: In Book Mode ON, navigateto a word (yellow) and let the video play. The yellow highlight should stay on its original line even as the white highlight moves.
- [ ] 2.2 Verify seek independence: In Book Mode ON, use `a`/`d` to seek. The yellow highlight should stay in place while the viewport and white line update.
- [ ] 2.3 Verify dismissal: Ensure that pressing `Esc` in Book Mode still correctly clears the stationary yellow highlight.
- [ ] 2.4 Verify regression: Ensure that in Book Mode OFF, the yellow highlight still follows/resets as intended for regular playback.
