# Implementation Tasks: Restore Auto-scrolling Repeat

## 1. Core Logic Update (lls_core.lua)

- [x] 1.1 Update `parse_and_bind` function signature to accept an optional `complex` boolean parameter.
- [x] 1.2 Modify `parse_and_bind` keyboard binding logic to use the `complex` parameter when creating the binding table.
- [x] 1.3 Ensure the `fn` wrapper in `parse_and_bind` correctly passes the event table `t` to the `key_fn`.

## 2. Binding Configuration

- [x] 2.1 Update the `parse_and_bind` call for `Options.dw_key_seek_prev` to pass `true` for the `complex` parameter.
- [x] 2.2 Update the `parse_and_bind` call for `Options.dw_key_seek_next` to pass `true` for the `complex` parameter.

## 3. Verification

- [x] 3.1 Verify that holding 'a' or 'd' in any Drum Window mode (Normal, Single Line, Reel, Window) triggers continuous subtitle seeking.
- [x] 3.2 Verify that releasing the key stops the seeking immediately.
- [x] 3.3 Verify that the initial delay (`seek_hold_delay`) and repeat rate (`seek_hold_rate`) are respected.
