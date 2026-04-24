## 1. Refactor Scrolling and Binding Logic

- [x] 1.1 Update `dw_ensure_visible(line_idx, paged)` to implement "Paged" (jump) vs "Pushed" (incremental) logic.
- [x] 1.2 Add safety clamping to `dw_ensure_visible` margin calculation.
- [ ] 1.3 Remove `a`, `d`, `ф`, `в` from the `repeatable` keys list in `manage_dw_bindings` to fix unresponsive seeking.

## 2. Fix Viewport Fighting and Selection

- [ ] 2.1 Update `tick_dw` to only auto-scroll if `FSM.DW_FOLLOW_PLAYER` is true AND the video is not currently being seeked manually.
- [ ] 2.2 Update `cmd_dw_seek_delta` to provide immediate "Push" scrolling and update both white and yellow pointers.
- [ ] 2.3 Modify `cmd_seek_with_repeat` to track a "seeking" state to prevent `tick_dw` from fighting the manual move.
- [ ] 2.4 Ensure the yellow cursor focus remains on the first word of the target subtitle after a seek.

## 3. Configuration and Validation

- [x] 3.1 Verify `dw_scrolloff` usage.
- [ ] 3.2 Test Book Mode ON manual navigation (`a`/`d`) for line-by-line pushing without viewport jitter.
- [ ] 3.3 Test Book Mode ON playback for page-by-page flipping at margins.
