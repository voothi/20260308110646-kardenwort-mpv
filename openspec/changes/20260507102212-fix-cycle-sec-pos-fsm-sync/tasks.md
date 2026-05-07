## 1. Code Fix

- [ ] 1.1 In `cmd_cycle_sec_pos` (line ~7449, else-branch), after `mp.set_property_number("secondary-sub-pos", n)`, add `FSM.native_sec_sub_pos = n`.
- [ ] 1.2 Verify the Drum branch (lines 7443–7445) is unchanged and still reads/writes `FSM.native_sec_sub_pos` correctly.

## 2. Spec Update

- [ ] 2.1 Merge the delta spec (`specs/fsm-architecture/spec.md` in this change) into `openspec/specs/fsm-architecture/spec.md`: append the new scenario "Toggle cycle syncs FSM state in all branches" under the existing "Secondary Position Bounds via Configuration" requirement and update the requirement description to mention toggle operations.

## 3. Smoke Test

- [ ] 3.1 With secondary subtitle loaded and `FSM.DRUM == "OFF"`: press `Shift+X` to toggle secondary pos to BOTTOM, confirm OSD shows correct position.
- [ ] 3.2 Enable Drum Mode (`FSM.DRUM == "ON"`): press `Shift+X` — confirm toggle direction is correct (if position was at BOTTOM, it should go to TOP).
- [ ] 3.3 Reverse: toggle back to BOTTOM while in Drum Mode, exit Drum Mode, press `Shift+X` — confirm non-Drum branch toggles correctly and `FSM.native_sec_sub_pos` is in sync.
