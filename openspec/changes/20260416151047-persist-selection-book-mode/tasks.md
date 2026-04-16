## 1. Core Logic Update

- [x] 1.1 Update `cmd_dw_seek_delta` in `scripts/lls_core.lua` to only update `DW_CURSOR_LINE` and reset `DW_CURSOR_WORD` if `DW_ANCHOR_LINE == -1`.
- [x] 1.2 Update `tick_dw` in `scripts/lls_core.lua` to only update `DW_CURSOR_LINE` if `DW_ANCHOR_LINE == -1`.

## 2. Verification

- [x] 2.1 Verify range selections do not "stretch" during `a`/`d` seeks (Standard Mode).
- [x] 2.2 Verify range selections do not "stretch" during active playback (Standard Mode).
- [x] 2.3 Verify "phantom" yellow word highlight is gone when navigating without a selection.
