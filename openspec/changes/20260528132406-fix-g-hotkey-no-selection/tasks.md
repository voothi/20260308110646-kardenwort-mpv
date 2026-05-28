## 1. Modify Anki Export Selection Logic

- [x] 1.1 Implement smart live playback focus fallback in `dw_anki_export_selection()` when no active selection is present
- [x] 1.2 Validate that when `FSM.DW_ANCHOR_LINE == -1` and `FSM.DW_CURSOR_WORD == -1`, the resolved line index `cl` dynamically corresponds to the playhead's current position

## 2. Refine Universal Cursor Synchronization

- [x] 2.1 Update universal cursor synchronization logic in `master_tick()` under follow mode (`FSM.DW_FOLLOW_PLAYER == true`)
- [x] 2.2 Ensure that `FSM.DW_CURSOR_LINE` tracks `active_idx` on every tick when `FSM.DW_ANCHOR_LINE == -1` and `FSM.DW_CURSOR_WORD == -1` in both Book Mode and standard mode
