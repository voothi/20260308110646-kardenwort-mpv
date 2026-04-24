# Design: Restoring Complex Binding Support in parse_and_bind

## Context
The Drum Window navigation logic relies on a central `manage_dw_bindings` function which uses a helper `parse_and_bind` to handle both keyboard and mouse inputs. Keyboard inputs are currently hardcoded to `complex = false`, meaning they only trigger on key-down and do not provide the detailed event table (including the `event` field) that MPV provides for complex bindings.

The `cmd_seek_with_repeat` function was designed to manage its own repeat timer by listening for `down` and `up` events. Without complex bindings, it only sees the initial `down` event (or a fallback single execution) and cannot detect when the key is released, breaking the custom repeat logic.

## Goals / Non-Goals

**Goals:**
- Extend `parse_and_bind` to support an optional `complex` flag for keyboard bindings.
- Ensure keyboard bindings marked as `complex` receive the MPV event table.
- Restore the `hold-to-repeat` behavior for `a` and `d` keys.

**Non-Goals:**
- Changing the behavior of existing mouse bindings.
- Modifying the core `cmd_seek_with_repeat` logic (which is already correct if it receives events).

## Decisions

### 1. Enhanced `parse_and_bind` Signature
Update `parse_and_bind` to:
`local function parse_and_bind(key_string, base_name, mouse_fn, key_fn, updates_selection, complex)`

### 2. Event Propagation
For keyboard keys where `complex` is true, the wrapper function will pass the event table `t` to `key_fn`:
```lua
fn = function(t)
    -- ... shield logic ...
    key_fn(t, false) -- passes table t which contains .event
end,
complex = true
```

### 3. Selective Complexity
Only apply `complex = true` to keys that specifically require it (seek keys). Most other Drum Window keys (copy, search, etc.) remain one-shot.

## Risks / Trade-offs
- **Risk**: Setting `complex = true` for keys that don't expect it might cause issues if they aren't written to handle a table argument.
- **Mitigation**: Only the seek keys will be updated to use the complex flag, and their handler `cmd_seek_with_repeat` is already designed for it.
