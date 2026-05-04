# Tasks: Unified Adaptive Replay Refinement

**ID**: 20260504174809-adaptive-subtitle-replay-refinement

## Phase 1: Configuration & FSM
- [x] 1.1 Add `replay_ms` and `replay_count` to `Options` in `lls_core.lua`.
- [x] 1.2 Initialize `REPLAY_ITERATIONS` and `GHOST_HOLD_EXPIRY` in `FSM`.

## Phase 2: Implementation
- [x] 2.1 Update `cmd_replay_sub` to implement adaptive start point logic.
- [x] 2.2 Update `tick_scheduled_replay` to support `REPLAY_ITERATIONS`.
- [x] 2.3 Implement the `GHOST_HOLD_EXPIRY` check in `master_tick`.
- [x] 2.4 Update `cmd_smart_space` to clear `GHOST_HOLD_EXPIRY` on down events.
- [x] 2.5 Transition `cmd_replay_sub` to subtitle-independent fixed-window logic.
- [x] 2.6 Update `tick_scheduled_replay` to ensure pause at end of segment.
- [x] 2.7 Unify `replay_count` logic for both `Autopause ON` and `OFF`.
- [x] 2.8 Silence `tick_autopause` during active replay/loop.
- [x] 2.9 Simplify `Autopause OFF` OSD and behavior (Flashback).

## Phase 3: Finalization
- [x] 3.1 Update `mpv.conf` with new defaults.
- [x] 3.2 Add block header comment in `lls_core.lua`.
- [x] 3.3 Final audit and cleanup.
