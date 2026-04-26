## 1. Foundation & Hit-Testing

- [ ] 1.1 Implement `calculate_osd_layout_meta` to generate word bounding boxes from text/font/position parameters.
- [ ] 1.2 Add `FSM.DRUM_HIT_ZONES` to the state machine to cache OSD word metadata and prevent redundant width calculations.
- [ ] 1.3 Update the `draw_drum` function to trigger metadata generation whenever the subtitle segment or visual position changes.

## 2. Event Handling & Interactivity

- [ ] 2.1 Generalize `dw_hit_test` to support querying the dynamic `DRUM_HIT_ZONES` metadata.
- [ ] 2.2 Extend mouse event listeners (`MBTN_LEFT`, `MBTN_LEFT_DBL`) to trigger when Drum Mode or SRT OSD is active.
- [ ] 2.3 Implement selection and hover logic for `drum_osd` using the generalized hit-test engine.
- [ ] 2.4 Add "Click-to-Pause" behavior for OSD interactivity to stabilize selection on moving subtitles.

## 3. Rendering & Visual Feedback

- [ ] 3.1 Update `format_sub` and `draw_drum` to respect `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD` even when the full Drum Window is closed.
- [ ] 3.2 Ensure Anki database highlights are correctly applied and interactive in the standard OSD viewports.

## 4. Configuration & Position Sync

- [ ] 4.1 Add `osd_interactivity` toggle to the `Options` table and `script-opts/lls.conf`.
- [ ] 4.2 Update `cmd_adjust_sub_pos` and `cmd_adjust_sec_sub_pos` to immediately invalidate and recalculate OSD hit-zones.
- [ ] 4.3 Add safety checks to the `master_tick` loop to clean up interactivity state when switching modes.
