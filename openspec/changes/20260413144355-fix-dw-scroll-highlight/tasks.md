## 1. Implement Mouse-to-Cursor Synchronization

- [x] 1.1 Extract hit-test and cursor update logic into a shared helper function `dw_sync_cursor_to_mouse()`.
- [x] 1.2 Refactor `dw_mouse_update_selection()` to use the new helper.

## 2. Fix Scroll Interaction

- [x] 2.1 Remove word-clearing logic from `cmd_dw_scroll()`.
- [x] 2.2 Add call to `dw_sync_cursor_to_mouse()` at the end of `cmd_dw_scroll()`.
- [x] 2.3 Verify that OSD updates immediately after a wheel scroll event.

## 4. Fix Regression

- [x] 4.1 Fix "Sticking" Selection Regression: Guard cursor updates in `dw_sync_cursor_to_mouse` to only occur during active dragging or when no selection is present.
- [x] 4.2 Restrict Yellow Highlight Synchronization: Only update logical cursor position during a scroll if `DW_MOUSE_DRAGGING` is true.



