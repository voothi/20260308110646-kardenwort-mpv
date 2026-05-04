# Proposal: Audio Padding for Subtitle Boundaries

## Summary
Introduce "Audio Padding Start" and "Audio Padding End" options to allow for temporal overlap at subtitle boundaries. This ensures that audio onsets and tails are fully audible during navigation and automated pauses, enhancing the immersion experience.

## Problem
Currently, `kardenwort-mpv` handles subtitle boundaries with high precision, but real-world audio often has breath or tail sounds that extend slightly beyond the technical subtitle timestamps. 
1. **Clipping**: When seeking to a subtitle (via `a`/`d` or double-click), the audio often starts abruptly, missing the sentence onset.
2. **Early Cut-off**: In `Autopause ON` mode, the current `pause_padding` (0.15s) triggers a pause *before* the subtitle ends, which can cut off the end of a sentence. Even at 0ms padding, the pause can feel premature for some audio tracks.

## What Changes
- Add two new configuration options: `lls-audio_padding_start` and `lls-audio_padding_end` (unit: milliseconds).
- Update seeking logic (`a`, `d`, Enter, Double Click) to apply `audio_padding_start` (seeking X ms earlier).
- Update `tick_autopause` to apply `audio_padding_end` (pausing X ms later).
- Ensure these paddings do not affect the subtitle-independent Replay (`s`) functionality.

## Capabilities

### New Capabilities
- `audio-padding`: Configuration and enforcement of temporal padding (pre-roll/post-roll) for all subtitle-bound navigation and automation actions.

### Modified Capabilities
- `navigation`: Seeking logic now incorporates optional temporal offsets.
- `autopause`: Automatic stopping triggers now support an adjustable post-roll buffer.

## Impact
- **lls_core.lua**: Modification of `Options` table, `tick_autopause`, and seeking functions (`cmd_dw_seek_delta`, `cmd_dw_seek_selected`, `cmd_dw_double_click`).
- **mpv.conf**: Addition of default values for the new padding options.
- **Documentation**: Update to help users calibrate their immersion environment.
