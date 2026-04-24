## 1. Refactor Scrolling Logic

- [ ] 1.1 Update `dw_ensure_visible(line_idx, paged)` to implement "Paged" (jump) vs "Pushed" (incremental) logic based on the `paged` boolean.
- [ ] 1.2 Add safety clamping to `dw_ensure_visible` to prevent oscillatory scrolling if `dw_scrolloff` is too large.
- [ ] 1.3 Ensure `dw_ensure_visible` uses `Options.dw_scrolloff` consistently for margins.

## 2. Update Navigation Handlers

- [ ] 2.1 Modify `tick_dw` to call `dw_ensure_visible(active_idx, true)` in Book Mode (enabling paged scrolling during playback).
- [ ] 2.2 Modify `cmd_dw_seek_delta` to call `dw_ensure_visible(target_idx, false)` in Book Mode (enabling pushed scrolling during manual seek).
- [ ] 2.3 Update `cmd_dw_seek_delta` to set `FSM.DW_CURSOR_WORD` to `1` (or closest word) to maintain Gold highlight visibility.
- [ ] 2.4 Verify `manage_dw_bindings` includes `a`, `d`, `ф`, `в` in the `repeatable` keys list.

## 3. Configuration and Validation

- [ ] 3.1 Verify `dw_scrolloff` is correctly read from `Options`.
- [ ] 3.2 Test Book Mode ON manual navigation (`a`/`d`) for line-by-line pushing.
- [ ] 3.3 Test Book Mode ON playback for page-by-page flipping at margins.
