## 1. Documentation Verification

- [x] 1.1 Verify that `proposal.md`, `design.md`, and `specs/fsm-architecture/spec.md` correctly reflect the `FSM` configurations in `lls_core.lua` (lines ~127-180).
- [x] 1.2 Verify that the `master_tick` and visibility toggles match the documented exclusive execution paths in the specification.

## 2. FSM Implementation Fixes

- [x] 2.1 Refactor `master_tick` to bypass continuous subtraction when `FSM.DRUM_WINDOW ~= "OFF"` (Fixes `20260413123947` overlapping window bug).
- [x] 2.2 Re-architect `master_tick` suppression `if` branches to explicitly catch `mp.get_property_bool("secondary-sub-visibility")` escaping false loops (Fixes `20260413130213` secondary sub duplicate artefact).
- [x] 2.3 Audit the fallback logic inside `master_tick` restoring native visibility to properly respect `FSM.native_sec_sub_vis` instead of forcefully asserting true or false.

## 3. Finalization

- [x] 3.1 Conclude the review successfully and confirm that all required FSM states were captured.
