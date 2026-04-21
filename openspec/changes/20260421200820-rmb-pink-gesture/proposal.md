## Why

The Drum Window's "Cool Path" (pink) highlighting currently requires either the `Ctrl` key or a dedicated keyboard key (`t`), making it inaccessible in pure mouse-only or remote-control workflows where no keyboard is reachable. Users who work through a mouse or IR remote need a way to mark a word range pink without touching the keyboard at all.

## What Changes

- Add a new two-button mouse gesture: holding LMB to drag-select a range, then pressing RMB while LMB is held, triggers the pink-highlight action on release of either button.
- The tooltip (currently bound to RMB standalone) MUST NOT open while LMB is held; it continues to function normally when LMB is not pressed.
- RMB-up while LMB is held commits the pink mark and clears the selection, symmetrically with LMB-up while RMB is held.
- Simultaneously releasing both buttons also commits the pink mark (whichever `up` event fires first wins; the second is a no-op due to a debounce guard).
- The `FSM` gains two new boolean flags (`DW_LMB_DOWN`, `DW_RMB_DOWN`) to track physical button state independently of the drag-selection state machine.
- A timestamp guard (`DW_RMB_GESTURE_LAST_TIME`) prevents double-firing when both buttons are released within 50 ms of each other.

## Capabilities

### New Capabilities
- `rmb-pink-gesture`: RMB held while LMB is down (or vice versa) commits the current yellow selection as pink, replacing the need for `Ctrl` or `t` in mouse-only mode.

### Modified Capabilities
- `lls-mouse-input`: Adds RMB physical-state tracking (`DW_RMB_DOWN`) and gesture routing logic; extends the tooltip-pin guard to suppress tooltip activation while LMB is physically held.

## Impact

- **Code**: `scripts/lls_core.lua` — FSM state block, `cmd_dw_tooltip_pin`, and the `make_mouse_handler` / binding infrastructure inside `manage_dw_bindings`.
- **No new config options** required (uses existing `dw_key_tooltip_pin` binding path).
- **No breaking changes** — existing Ctrl+LMB and `t` key pink-highlighting remain fully functional.
