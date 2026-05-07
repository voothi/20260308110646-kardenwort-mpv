## 1. Fix: cmd_toggle_sub_vis blocked by Drum Window

- [x] 1.1 In `cmd_toggle_sub_vis` (line ~7415), remove the `if FSM.DRUM_WINDOW ~= "OFF" then … return end` guard entirely.
- [x] 1.2 Verify the remaining function body is intact: `FSM.native_sub_vis` toggle, `FSM.native_sec_sub_vis` toggle, the conditional `sub-visibility` property set (for OFF case), the OSD message, and the `master_tick()` call.
- [ ] 1.3 Manual smoke test: open DW, press 's', confirm no crash and DW renders unchanged; close DW, confirm subtitles are in the toggled state.

## 2. Fix: get_center_index uses primary sentinel for secondary track

- [x] 2.1 In `get_center_index` (line ~685), change `local active_idx = FSM.ACTIVE_IDX` to `local active_idx = (subs == Tracks.pri.subs) and FSM.ACTIVE_IDX or -1`.
- [x] 2.2 Verify the jerk-back override block (PHRASE mode + JUST_JERKED_TO) is unchanged — it still runs only when the result of the line above is non-negative, so secondary calls skip it automatically.
- [ ] 2.3 Manual smoke test with dual SRT tracks loaded: scrub playback, confirm primary track focus sentinel behaves as before; confirm secondary track does not snap incorrectly on long audio-padding values.

## 3. Fix: cmd_adjust_sec_sub_pos does not sync FSM.native_sec_sub_pos

- [x] 3.1 In `cmd_adjust_sec_sub_pos` (line ~7466), extract the computed position into a local: `local new_pos = math.max(0, math.min(150, p + delta))`.
- [x] 3.2 Set the mpv property using `new_pos`: `mp.set_property_number("secondary-sub-pos", new_pos)`.
- [x] 3.3 Add the sync write: `FSM.native_sec_sub_pos = new_pos`.
- [ ] 3.4 Manual smoke test: adjust secondary pos via delta key, enter Drum Mode, press cycle-secondary-pos — confirm toggle direction matches current visual position.

## 4. Spec Verification

- [ ] 4.1 Confirm `openspec/specs/fsm-architecture/spec.md` is updated with the three MODIFIED requirements from this change (run `openspec archive` or verify manually).
