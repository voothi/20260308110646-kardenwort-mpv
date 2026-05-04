## Why

When operating in Drum Mode (on-screen overlay) and using continuous playback with Spacebar (Autopause ON), the "clipboard focus" (internal state `FSM.DW_CURSOR_LINE`) fails to synchronize with the active playback line. If this cursor state is set by any prior manual interaction (such as a mouse click or navigating via `a`/`d`), it becomes permanently stuck at that index. Consequently, triggering a subtitle copy (e.g., via `Ctrl+C`) incorrectly captures the stuck subtitle rather than the current on-screen subtitle. This change ensures the cursor always properly tracks playback when in "follow player" mode.

## What Changes

- Abstract the cursor synchronization logic out of `tick_dw` (which only executes when the dedicated Drum Window is open) and migrate it into the global `master_tick` loop.
- Ensure that `FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, and `FSM.DW_VIEW_CENTER` are properly synchronized with `active_idx` whenever `FSM.DW_FOLLOW_PLAYER` is true, regardless of whether Drum Window or Drum Mode is active.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `drum-window-state-fix`: Modify the synchronization requirement to ensure cursor tracks active line in Drum Mode as well as Drum Window mode.

## Impact

- `scripts/lls_core.lua`: Modifications will be made primarily to `master_tick` and `tick_dw` to re-route state synchronization.
