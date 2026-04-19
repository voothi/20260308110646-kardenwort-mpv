## 1. Unified Shortcut Engine

- [x] 1.1 Implement multi-delimiter parser in `parse_and_bind` supporting space, comma, and semicolon.
- [x] 1.2 Transition `mpv.conf` parameters (`dw_key_pair`, `dw_key_add`, etc.) to the new list format.
- [x] 1.3 Add closure-based context passing (`was_mouse`) to all unified bindings.

## 2. Interaction State Hardening

- [x] 2.1 Remove the legacy `ctrl_discard_set()` trigger from the `Ctrl` key release event.
- [x] 2.2 Implement an explicit `Ctrl+ESC` shortcut for clearing the pending paired selection set.
- [x] 2.3 Ensure pairing triggers (`cmd_dw_toggle_pink`) update the focus cursor and anchor position immediately.

## 3. Range-Aware Selection Logic

- [x] 3.1 Implement the `get_dw_selection_bounds` helper to detect active yellow ranges.
- [x] 3.2 Update `cmd_dw_toggle_pink` to iterate over and toggle entire selection ranges.
- [x] 3.3 Apply `make_mouse_handler` to mouse-based pairing shortcuts to enable "drag-to-pair" visual feedback.
- [x] 3.4 Verify that range-based pairing automatically clears the temporary yellow selection upon completion.
