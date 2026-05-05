# Tasks: Audio Padding Sentinel (ZID: 20260505021903)

## 1. Foundation and Configuration

- [ ] 1.1 Add `audio_padding_start` and `audio_padding_end` (default 0) to `Options` in `lls_core.lua`.
- [ ] 1.2 Initialize `FSM.active_idx = -1` and `FSM.active_idx_locked = false` for state management.
- [ ] 1.3 Update `mpv.conf` example or internal defaults to reflect new padding options.

## 2. Core Logic Upgrades

- [ ] 2.1 Implement `get_effective_boundaries(sub)` helper function to apply padding.
- [ ] 2.2 Refactor `master_tick` to maintain a "Sticky Focus" on `FSM.active_idx`.
- [ ] 2.3 Modify the index selection logic to prefer the "current" subtitle if it's within its padded `eff_end`.

## 3. Navigation and Seeking

- [ ] 3.1 Update `navigate_sub` (used by `a`/`d`) to target the `eff_start` of the destination subtitle.
- [ ] 3.2 Update `jump_to_sub` (used by mouse double-click and Enter) to respect `audio_padding_start`.

## 4. Automation Controllers

- [ ] 4.1 Harden `tick_autopause` to use the "Sticky Focus" and its `eff_end` for trigger detection.
- [ ] 4.2 Sync `tick_loop` and `tick_scheduled_replay` to use padded boundaries for consistency.

## 5. Verification and Polish

- [ ] 5.1 Test with `Autopause ON` and 200ms padding to ensure the "Continuous Chain" bug is resolved.
- [ ] 5.2 Verify that visual highlighting stays on the current subtitle until the audio tail is finished.
- [ ] 5.3 Audit for regression in "Space-hold" streaming (Ghost Hold Recovery).
