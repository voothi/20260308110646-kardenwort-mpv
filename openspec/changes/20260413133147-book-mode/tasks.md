## 1. State Management and Configuration Options

- [ ] 1.1 Add `book_mode = false` to the default options/settings table at the top of `kardenwort-mpv.lua`.
- [ ] 1.2 Read the user configuration (e.g., `script-opts=lls-book_mode`) into the options table.
- [ ] 1.3 Declare a mutable local variable `is_book_mode` and initialize it using the read configuration option `book_mode`.

## 2. Interaction Supression Logging

- [ ] 2.1 Find the logic handling manual subtitle navigation keys (`a`, `d`, or their backend functions like `seek_sub`). Inside that logic, there is a mechanism resetting `state.drum_window`. Wrap it specifically: `if not is_book_mode then state.drum_window = false end`.
- [ ] 2.2 Find the logic handling the left-mouse double-click (e.g., `handle_mbtn_left_dbl` or similar vocab parsing event). Locate the part where it collapses the window mode, and suppress it: `if not is_book_mode then state.drum_window = false end`.

## 3. Dedicated Toggling Keybindings

- [ ] 3.1 Create a new Lua function `toggle_book_mode()`. This function must toggle the `is_book_mode` boolean.
- [ ] 3.2 In `toggle_book_mode()`, add logic to automatically enforce Drum Window mode (`state.drum_window = true`) explicitly when toggled to `true`.
- [ ] 3.3 Broadcast an OSD message in `toggle_book_mode()`: "Book Mode: ON" or "Book Mode: OFF".
- [ ] 3.4 Bind the `toggle_book_mode()` function directly to the keys `b` and `и` using `mp.add_forced_key_binding`.

## 4. Default Configuration Updating

- [ ] 4.1 Update the `mpv.conf` file to include `script-opts-append=lls-book_mode=no` with a comment explaining its purpose (e.g., "permanently locks Drum Window view preventing regression to normal drum mode").
