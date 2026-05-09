## 1. Implement Synchronous Suppression

- [x] 1.1 Update `cmd_cycle_sec_sid` in `lls_core.lua` to set `secondary-sub-visibility` to `false` immediately if custom OSD rendering (Drum/SRT) is active.
- [x] 1.2 Update the `secondary-sid` property observer in `lls_core.lua` to enforce `secondary-sub-visibility` suppression synchronously after updating media state.
- [x] 1.3 Add an immediate `drum_osd:update()` call after changing the secondary SID in `cmd_cycle_sec_sid` to ensure visual responsiveness.

## 2. Verification

- [x] 2.1 Start mpv in Drum Mode with an SRT file.
- [x] 2.2 Cycle secondary subtitles and verify that no native subtitles "flash" during the transition.
- [x] 2.3 Verify that the OSD text updates immediately upon track selection.
- [x] 2.4 Disable Drum Mode and verify that `secondary-sub-visibility` is correctly restored if `FSM.native_sec_sub_vis` is true.
