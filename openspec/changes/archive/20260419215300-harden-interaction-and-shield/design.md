# Design: Interaction Shielding Mechanism

## State Model
Add `DW_MOUSE_LOCK_UNTIL` to the `FSM` table.
- Default: `0`
- Format: `mp.get_time()` value.

## Interaction Flow
### 1. Keyboard Trigger (`parse_and_bind`)
When a keyboard binding is executed:
```lua
FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + 0.150
```

### 2. Mouse Suppression (`make_mouse_handler`)
On any mouse button event, verify shield state immediately:
```lua
if mp.get_time() < FSM.DW_MOUSE_LOCK_UNTIL then return end
```
This causes the script to completely drop any "jitter" clicks sent by hardware/software combos during remote use.

## Structural Hardening
Renamed and cleaned context flags in `cmd_dw_toggle_pink`:
- Replaced ambiguous pattern matching with strict `is_mouse` boolean context.
- Ensured mouse polling (`dw_get_mouse_osd`) only occurs if `is_mouse` is true.
