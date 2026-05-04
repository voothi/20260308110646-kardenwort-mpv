# Tasks: Adaptive Subtitle Replay Refinement

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

## Phase 3: Verification
- [ ] 3.1 Verify "Ghost Release" fix: hold Space, press S, release Space during replay -> should pause at end.
- [ ] 3.2 Verify adaptive segment: long sub, press S mid-way -> should jump back X ms, not to start.
- [ ] 3.3 Verify repeat count: set `replay_count = 2`, press S -> should play twice then pause.
