# Tasks: Audio Padding Boundaries

## 1. Configuration & Options

- [ ] 1.1 Add `audio_padding_start` and `audio_padding_end` to the `Options` table in `scripts/lls_core.lua`. Initialize both to `0`.
- [ ] 1.2 Update `mpv.conf` with commented default values for `lls-audio_padding_start` and `lls-audio_padding_end` in the "AutoPause Settings" section.

## 2. Navigation & Seeking Implementation

- [ ] 2.1 Update `cmd_dw_seek_delta` to apply `audio_padding_start` to the seek time.
- [ ] 2.2 Update `cmd_dw_seek_selected` to apply `audio_padding_start` to the seek time.
- [ ] 2.3 Update `cmd_dw_double_click` to apply `audio_padding_start` to the seek time.
- [ ] 2.4 Ensure all modified seek calls use `math.max(0, ...)` to prevent negative time errors.

## 3. Autopause Automation Implementation

- [ ] 3.1 Modify `tick_autopause` in `scripts/lls_core.lua` to calculate an `effective_sub_end` by adding `audio_padding_end` to the base `sub_end`.
- [ ] 3.2 Update the pause condition in `tick_autopause` to use `effective_sub_end` while preserving the existing `pause_padding` logic.

## 4. Verification & Testing

- [ ] 4.1 Verify that pressing `a` or `d` (seek prev/next) starts playback slightly before the subtitle text appearance (when padding is > 0).
- [ ] 4.2 Verify that in `Autopause ON` mode, the video pauses after the subtitle text has fully disappeared (when padding is > 0).
- [ ] 4.3 Verify that double-clicking a word in the Drum Window seeks with the appropriate padding.
- [ ] 4.4 Verify that the `s` (Replay) key continues to loop based on a fixed 2s window, unaffected by boundary padding.
