## 1. State Management and Configuration Options

- [x] 1.1 Add `book_mode = false` to the default options/settings table at the top of `lls_core.lua`.
- [x] 1.2 Read the user configuration (e.g., `script-opts=lls-book_mode`) into the options table.
- [x] 1.3 Initialize `FSM.BOOK_MODE` using the read configuration option `book_mode`.

## 2. Stationary Viewport and Interaction Suppression

- [x] 2.1 Modify `tick_dw` to suppress automatic viewport scrolling (`FSM.DW_VIEW_CENTER`) when `FSM.BOOK_MODE` is active.
- [x] 2.2 Update navigation handlers (`cmd_dw_seek_delta`, `cmd_dw_double_click`) to bypass viewport snap-back when in Book Mode, while still allowing the video to seek.

## 3. Dedicated Toggling Keybindings

- [x] 3.1 Create a new Lua function `toggle_book_mode()` that toggles `FSM.BOOK_MODE`.
- [x] 3.2 In `toggle_book_mode()`, ensure Drum Window mode is engaged when toggling to ON.
- [x] 3.3 Broadcast an OSD message: "Book Mode: ON" or "Book Mode: OFF".
- [x] 3.4 Bind the function to `b` and `и` using `mp.add_forced_key_binding`.

## 4. Default Configuration Updating

- [x] 4.1 Update `mpv.conf` to include `script-opts-append=lls-book_mode=no` with a descriptive comment.
