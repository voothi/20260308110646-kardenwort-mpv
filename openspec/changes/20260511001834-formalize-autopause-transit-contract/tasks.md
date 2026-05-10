## 1. Contract and Scope Lock

- [x] 1.1 Link implementation to the `playback-change-interface` contract fields (Goal, Trigger, Expected, Must-Not-Change, Acceptance, Scope) for this change.
- [x] 1.2 Add or confirm acceptance scenarios for inside-card rewind, cross-card rewind, replay `s`, and PHRASE restoration after transit.

## 2. Transit Split Implementation

- [x] 2.1 Update `cmd_seek_time` / replay entry logic in `scripts/lls_core.lua` to classify inside-card vs cross-card transitions and set transit inhibit only for cross-card cases.
- [x] 2.2 Update `tick_autopause` gating so autopause suppression applies only during active cross-card transit inhibit.
- [x] 2.3 Update PHRASE jerk-back gate in `master_tick` so jerk-back is suppressed only while cross-card transit inhibit is active.

## 3. Inhibit Lifecycle Hygiene

- [x] 3.1 Ensure deterministic inhibit clear conditions after transit completion (avoid timer-only expiration semantics).
- [x] 3.2 Ensure stale inhibit is cleared on unrelated manual navigation handlers before new navigation state is applied.

## 4. Validation and Regression Guard

- [x] 4.1 Run focused acceptance checks for overlap-heavy fixtures covering Shift+a/d and `s` replay in Autopause ON + PHRASE.
- [ ] 4.2 Verify non-regression boundaries: ordinary PHRASE forward playback, MOVIE baseline behavior, Drum Window UI behavior.
- [x] 4.3 Document verification results in change notes and prepare for `/opsx:apply` execution review.
