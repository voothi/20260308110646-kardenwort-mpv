# Tasks: Simplify Selection Logic via FSM State

- [x] 1. Add `DW_CTRL_PENDING_LIST` to `FSM` initialization.
- [x] 2. Implement `sync_ctrl_pending_list()` helper.
- [x] 3. Integrate `sync_ctrl_pending_list()` into `ctrl_toggle_word` and `cmd_dw_toggle_pink`.
- [x] 4. Update all reset paths (`dw_reset_selection`, `ctrl_discard_set`, `cmd_dw_esc`) to clear the list.
- [x] 5. Refactor `get_clipboard_text_smart` and `ctrl_commit_set` to use the pre-sorted list.
- [x] 6. Verify cross-mode functionality (Drum, DW, SRT, Tooltip).
- [x] 7. Optimize `cmd_dw_toggle_pink` to call sync once after the loop.
