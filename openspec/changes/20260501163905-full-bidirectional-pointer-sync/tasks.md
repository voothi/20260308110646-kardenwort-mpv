## 1. Audit and Refactor Toggle Logic

- [ ] 1.1 Remove `FSM.DW_CURSOR_WORD = -1` from `cmd_toggle_drum_window` (line 6080) to preserve word pointer during opening.
- [ ] 1.2 Implement viewport synchronization in `cmd_toggle_drum_window`: if `FSM.DW_CURSOR_LINE ~= -1`, set `FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE`.
- [ ] 1.3 Ensure `FSM.DW_CURSOR_LINE` is correctly initialized from playback time if opening for the first time without a pointer.

## 2. Hardening SRT-OSD Pointer Rendering

- [ ] 2.1 Refactor `tick_drum_osd` to ensure it checks `FSM.DW_CURSOR_WORD` even when `FSM.DRUM == "OFF"`.
- [ ] 2.2 Verify that `draw_sub_with_highlights` is correctly called in the SRT rendering path to show the yellow highlight.

## 3. Verification and Regression Testing

- [ ] 3.1 **Test Case C -> W**: Set a yellow pointer in Drum Mode (C), open Drum Window (W). Pointer must be preserved and window must jump to that line.
- [ ] 3.2 **Test Case W -> C**: Set a yellow pointer in Drum Window (W), close window. Pointer must be preserved in Drum Mode (C).
- [ ] 3.3 **Test Case SRT -> W**: Navigate with arrows in Regular SRT mode to set a pointer, open Drum Window. Pointer and viewport must sync.
- [ ] 3.4 **Regression**: Ensure that clearing the pointer with `Esc` still works correctly in all modes (Sequential logic).
