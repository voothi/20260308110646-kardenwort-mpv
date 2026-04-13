## 1. Harden Master Tick Suppression

- [ ] 1.1 Refactor the visibility management block in `master_tick` to include `FSM.DRUM_WINDOW ~= "OFF"` in the suppression condition.
- [ ] 1.2 Ensure that if any OSD rendering mode is active (Drum Mode, OSD-SRT, or Drum Window), native subtitles are forced to `false` periodically.
- [ ] 1.3 Verify that the logic correctly restores native subtitles based on `FSM.native_sub_vis` when neither Drum Mode nor Drum Window is active.

## 2. Secure Track Transitions

- [ ] 2.1 Update `update_media_state` to prevent visibility restoration during track changes if the Drum Window is active.
- [ ] 2.2 Ensure the "auto-disable Drum Mode" block in `update_media_state` respects the Drum Window state when deciding to restore native properties.

## 3. Validation

- [ ] 3.1 Open the Drum Window (`w`) and cycle subtitle tracks (`j`). Verify that native subtitles do not appear above the window.
- [ ] 3.2 Close the Drum Window and verify that standard subtitle rendering (native or OSD-SRT) resumes correctly based on current configuration.
