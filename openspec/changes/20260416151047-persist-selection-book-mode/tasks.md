## 1. Core Logic Update

- [x] 1.1 Update `cmd_dw_seek_delta` in `scripts/lls_core.lua` to properly manage `DW_CURSOR_LINE` and `DW_CURSOR_WORD`.
- [x] 1.2 Update `tick_dw` in `scripts/lls_core.lua` to make `DW_CURSOR_LINE` update conditional on `DW_ANCHOR_LINE == -1`.
- [x] 1.3 Add a `pause` property observer in `scripts/lls_core.lua` to set `DW_TOOLTIP_TARGET_MODE = "ACTIVE"` when playback starts.

## 2. Verification

- [x] 2.1 Verify range selections do not "stretch" during navigation or playback.
- [x] 2.2 Verify tooltip stays on the last active subtitle after autopause even if a yellow selection exists.
- [x] 2.3 Verify tooltip switches to selection cursor on manual interaction (e.g., arrow keys).
