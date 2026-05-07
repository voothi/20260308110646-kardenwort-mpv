## Why

Three correctness gaps in the FSM architecture were identified during a post-v1.58.50 audit (ZID 20260507082627): the global subtitle toggle is incorrectly suppressed inside Drum Window mode, the secondary track index resolution silently uses a mismatched primary sentinel, and `FSM.native_sec_sub_pos` drifts from the actual mpv property. All three are state-management defects with no visual consequence — they are fixed now while the UI is stable to prevent harder-to-diagnose bugs as complexity grows.

## What Changes

- `cmd_toggle_sub_vis`: Remove the early-return guard that blocks execution when `FSM.DRUM_WINDOW ~= "OFF"`. The 's' key must update `FSM.native_sub_vis` uniformly regardless of active mode, per spec.
- `get_center_index`: Add an explicit `subs_owner` parameter (or use caller-passed sentinel) so secondary-track resolution uses its own per-track sentinel instead of the global `FSM.ACTIVE_IDX` which tracks the primary track.
- `cmd_adjust_sec_sub_pos`: After setting the mpv property, sync the new value back into `FSM.native_sec_sub_pos` to keep FSM desired-state consistent with the actual player property.

## Capabilities

### New Capabilities

_(none — all changes are corrections to existing behavior)_

### Modified Capabilities

- `fsm-architecture`: Three requirement-level corrections — sub-toggle bypass, secondary sentinel independence, and secondary position state sync.

## Impact

- `scripts/lls_core.lua`: surgical edits to three functions (`cmd_toggle_sub_vis`, `get_center_index`, `cmd_adjust_sec_sub_pos`).
- No changes to OSD rendering, layout, highlighting, or playback logic.
- No new Options keys, no new FSM fields (beyond syncing an existing one).
- No impact on Drum Mode, Drum Window, search, autopause, or jerk-back logic.
