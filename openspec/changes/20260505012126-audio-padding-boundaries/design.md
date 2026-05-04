# Design: Audio Padding Boundaries

## Context
The current system handles subtitle boundaries precisely using timestamps from the subtitle track. While accurate, this often misses the natural "breathing room" of the audio, where speech begins slightly before or ends slightly after the technical subtitle timestamps. 

## Goals / Non-Goals

**Goals:**
- Provide user-configurable pre-roll (`audio_padding_start`) and post-roll (`audio_padding_end`) for all subtitle-bound actions.
- Implement these offsets in a way that feels natural in both `Autopause ON` and `OFF` modes.
- Ensure zero regression for the subtitle-independent Replay (`s`) mode.

**Non-Goals:**
- Modifying the subtitle parser or the actual timestamps of the subtitles.
- Changing the behavior of the fixed-window replay (`replay_ms`).
- Implementing complex audio analysis to "detect" the padding automatically.

## Decisions

### 1. Millisecond Configuration, Second Implementation
To match user intuition, options will be set in milliseconds (`ms`). However, all internal MPV calculations and `lls_core.lua` logic will convert these to seconds (`ms/1000`) for consistency with `time-pos` and `sub-start`/`sub-end`.

### 2. Seek-Start Adjustment
All functions that initiate a seek to a subtitle boundary (`cmd_dw_seek_delta`, `cmd_dw_seek_selected`, `cmd_dw_double_click`) will be modified to use:
`seek_time = math.max(0, sub.start_time - (Options.audio_padding_start / 1000))`
This ensures that the player always starts a bit early, catching the initial onset of the phrase.

### 3. Autopause-End Adjustment
The `tick_autopause` function will be modified to use an "Effective End":
`effective_sub_end = sub_end + (Options.audio_padding_end / 1000)`
The existing `pause_padding` logic will then operate relative to this `effective_sub_end`:
`if (effective_sub_end - time_pos) < Options.pause_padding then ...`
This allows the user to listen to the phrase completely (and even a bit beyond) before the autopause kicks in.

### 4. Exclusion of Replay (`s`)
The `cmd_replay_sub` function remains unchanged. Since it already calculates its start point as `time_pos - replay_ms`, it is already decoupled from subtitle boundaries and effectively provides its own "padding".

## Risks / Trade-offs

- **Overlapping Boundaries**: If paddings are set too high, a seek might land inside the *previous* subtitle's range. However, since the script relies on `time-pos` to determine the "active" subtitle, this is mostly a user-calibration issue.
- **Complexity in `tick_autopause`**: Adding an extra offset to the autopause trigger needs careful handling of `nil` values and track boundaries. 
- **User Confusion**: Having both `pause_padding` (which acts as a trigger buffer) and `audio_padding_end` (which acts as a boundary shift) might be confusing. The documentation in `mpv.conf` must clarify that `audio_padding_end` shifts the boundary forward, while `pause_padding` determines how close to that boundary we pause.
