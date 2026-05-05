## 1. Subtitle Navigation Hardening

- [x] 1.1 Implement modulo-based cyclic wrap-around in `cmd_dw_seek_delta` for `a` and `d` commands.
- [x] 1.2 Add OSD feedback for cyclic navigation transitions (e.g., "Wrapped to START/END").
- [x] 1.3 Add `math.max(0, s)` guard to seek commands to prevent invalid negative offsets.

## 2. Boundary Condition Debugging

- [x] 2.1 Audit `get_center_index` for stability at `time_pos` zero and boundary conditions.
- [x] 2.2 Fix the "switch to last" bug in Phrases mode by ensuring `FSM.ACTIVE_IDX` doesn't jump to `#subs` on initialization or reset.
- [x] 2.3 Implement manual nav cooldown in the Universal Jump Detection block for OSC synchronization.
- [x] 2.4 Add safety jump limit (max 5 subs) to Phrase mode "Jerk Back" logic.

## 3. Verification

- [x] 3.1 Verify cyclic navigation from first to last sub.
- [x] 3.2 Verify cyclic navigation from last to first sub.
- [x] 3.3 Verify Phrases mode behavior at the beginning of the track to ensure no automatic jumps.
- [x] 3.4 Verify OSC timeline seek synchronization and state stabilization.
