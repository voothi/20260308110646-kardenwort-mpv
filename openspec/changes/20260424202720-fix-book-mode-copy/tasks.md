## 1. Core Logic Update

- [ ] 1.1 Locate `cmd_dw_seek_delta` in `scripts/lls_core.lua`.
- [ ] 1.2 Refactor the conditional block to decouple `FSM.DW_VIEW_CENTER` update (Standard Mode only) from `FSM.DW_CURSOR_LINE` update (All modes, if no anchor).
- [ ] 1.3 Verify that `FSM.DW_CURSOR_WORD` and `FSM.DW_CURSOR_X` are also reset during the synchronized cursor update.

## 2. Verification

- [ ] 2.1 Test Case: Enter Book Mode, seek with `a`/`d`. Verify yellow focus moves to the new line but viewport stays stationary.
- [ ] 2.2 Test Case: In Book Mode, seek to a new line and press `Ctrl+C`. Verify the correct (new) subtitle is copied to clipboard.
- [ ] 2.3 Test Case: In Book Mode, select a specific word. Seek with `a`/`d`. Verify the yellow highlight stays on the selected word and doesn't follow the seek.
- [ ] 2.4 Test Case: Turn Book Mode OFF. Verify Standard Mode still scrolls and updates focus as before.
