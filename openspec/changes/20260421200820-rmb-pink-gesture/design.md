## Context

The Drum Window binds `MBTN_RIGHT` to `cmd_dw_tooltip_pin`. This handler is registered through `parse_and_bind` using `make_mouse_handler`, or directly if the function is already a `MOUSE_HANDLERS` member. The current `make_mouse_handler` wrapper knows nothing about the physical state of the *other* mouse button; it only tracks drag-selection state (`DW_MOUSE_DRAGGING`) for the key it is wrapping.

Three previous attempts all failed because they tried to intercept the gesture inside the generic `make_mouse_handler` factory, where the key identity (`tbl.key_name`) was unreliable in mpv's complex binding callbacks, and because the tooltip-pin guard was added *after* the gesture logic had already been attempted incorrectly.

The baseline code (commit `a1d1a0c8`) is the clean starting point for this change.

## Goals / Non-Goals

**Goals:**
- Track physical LMB / RMB press/release state in two dedicated FSM booleans: `DW_LMB_DOWN` and `DW_RMB_DOWN`.
- When RMB is pressed while LMB is already held (i.e., `DW_MOUSE_DRAGGING == true`), suppress tooltip opening.
- When either button is released while the other is held, call `cmd_dw_toggle_pink(tbl, true)` and early-return, consuming the event so normal selection/tooltip logic is not executed.
- A 50 ms timestamp guard prevents double-firing on simultaneous releases.
- After firing, forcibly reset `DW_MOUSE_DRAGGING = false` and both `_DOWN` flags to avoid phantom state.

**Non-Goals:**
- Changing how Ctrl+LMB or the `t` key work.
- Supporting RMB-only drag selection.
- Changing any configuration options.

## Decisions

### Decision 1: Dedicated wrapper functions, NOT modifications to `make_mouse_handler`

**Chosen:** Create two *named* wrapper closures (`cmd_dw_lmb_select` and `cmd_dw_rmb_tooltip`) that replace the bare `cmd_dw_mouse_select` and `cmd_dw_tooltip_pin` bindings in the `keys` table. Each wrapper sets the appropriate `_DOWN` flag at the very first line, *before* any shield-logic or early-return. This guarantees state accuracy regardless of shield status.

**Alternative rejected:** Modifying `make_mouse_handler` to detect left/right from `tbl.key_name`. This failed in all three previous attempts because mpv does not guarantee `tbl.key_name` is populated in all binding contexts, especially when the function is registered via `mp.add_forced_key_binding`.

**Alternative rejected:** Using a single shared wrapper. Clarity and debuggability require two dedicated closures.

### Decision 2: RMB state is tracked in `cmd_dw_rmb_tooltip`, NOT in `make_mouse_handler`

The `cmd_dw_tooltip_pin` function is registered *directly* (it is already a simple function, not produced by `make_mouse_handler`). Its wrapper closure sets `FSM.DW_RMB_DOWN` first, then checks `FSM.DW_LMB_DOWN` to suppress tooltip and trigger the pink gesture on "up", or suppress opening on "down".

### Decision 3: Gesture fires on *either* button release while the other is held

Both the LMB wrapper (on "up") and the RMB wrapper (on "up") check whether the other button is currently down. Whichever fires first calls `cmd_dw_toggle_pink`. The timestamp guard (`DW_RMB_GESTURE_LAST_TIME`) makes the second firing a no-op.

### Decision 4: Suppress tooltip on RMB "down" if LMB is held

In `cmd_dw_rmb_tooltip`, at the "down" branch: if `FSM.DW_LMB_DOWN == true`, set `FSM.DW_RMB_DOWN = true` and return immediately (no tooltip open). This eliminates the race condition that caused the tooltip to flicker on the first word.

## Risks / Trade-offs

- **[Risk] State desync if Drum Window is closed mid-gesture** → Mitigation: `manage_dw_bindings(false)` resets `DW_LMB_DOWN`, `DW_RMB_DOWN`, and `DW_RMB_GESTURE_LAST_TIME` to their initial values before removing bindings.
- **[Risk] 50 ms guard too short for slow hardware** → Mitigation: Guard only prevents *double* pink commits; a second intentional gesture 50 ms later is essentially impossible in human use. The guard can be documented as configurable later.
- **[Trade-off] RMB tooltip behavior differs slightly**: If the user presses RMB while LMB is held, no tooltip appears for that gesture. This is the intended and documented behavior — the user explicitly chose the gesture mode.

## Migration Plan

1. Add `DW_LMB_DOWN`, `DW_RMB_DOWN`, `DW_RMB_GESTURE_LAST_TIME` to the FSM state block.
2. Write `cmd_dw_lmb_select`: a closure wrapping the LMB "down/up" path. Sets `DW_LMB_DOWN` first. On "up", checks `DW_RMB_DOWN`; if true, fires pink gesture and early-returns.
3. Rewrite `cmd_dw_rmb_tooltip`: sets `DW_RMB_DOWN` first. On "down", if `DW_LMB_DOWN`, early-return. On "up", if `DW_LMB_DOWN`, fires pink gesture and early-returns; else delegates to original tooltip logic.
4. In `manage_dw_bindings`, replace the bare `cmd_dw_mouse_select` binding with `cmd_dw_lmb_select`, and the `cmd_dw_tooltip_pin` binding with `cmd_dw_rmb_tooltip`.
5. In `manage_dw_bindings(false)` cleanup: reset all three new FSM fields.

## Open Questions

- None. The design is fully specified based on analysis of the three failed attempts and the baseline code.
