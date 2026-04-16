## Context

The `lls_core.lua` script handles subtitle rendering through several paths: Standard Mode (SRT), Drum Mode (C), and Drum Window (W). Currently, the "active" state (highlighted in white) in Standard and Drum modes is determined by a strict range comparison: `time_pos >= start_time and time_pos <= end_time`. This causes a regression when using seek commands ('a', 'd') because MPV's seek landing might be slightly outside this range (e.g. 1ms early), resulting in a gray (dimmed) subtitle that only turns white after playback starts.

## Goals / Non-Goals

**Goals:**
- Ensure that the current subtitle is consistently highlighted in white during navigation and playback.
- Synchronize highlighting behavior between all OSD modes (Standard, Mode C, and Mode W).
- Eliminate visual artifacts (flickering from white to gray) during sequential navigation.

**Non-Goals:**
- Changing subtitle parsing or timing metadata.
- Adjusting the `get_center_index` snapping algorithm.

## Decisions

- **Adopt Centered-Line Highlighting**: Modify the `draw_drum` function (used for Standard and Mode C) to treat the `center_idx` line as "active" by default. This aligns it with `draw_dw` (Drum Window), which correctly highlights the centered line even in gaps.
- **Index-Based Active Check**: Instead of re-evaluating `time_pos` inside `draw_drum`, the rendering loop will trust that the `center_idx` passed from the high-level tick logic (`tick_drum`) is the intended focal point.

## Risks / Trade-offs

- **Highlight Persistence**: Highlighting the centered subtitle white during large gaps between lines might be seen as unexpected in "Standard" mode (where only one line is visible). However, since the script already chooses to display the nearest line rather than hiding it, being "white" is more readable and consistent with the user's experience in the Drum Window.
