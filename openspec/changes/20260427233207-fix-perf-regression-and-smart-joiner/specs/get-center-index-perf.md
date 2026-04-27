# Spec: Subtitle Centering Performance Optimization

## Context
The `get_center_index` function was duplicated, with a linear scan ($O(N)$) shadowing the correct binary search ($O(\log N)$) implementation. This causes significant CPU overhead during the 50ms `master_tick` loop on large subtitle tracks.

## Requirements
- **Performance**: The `get_center_index` function MUST operate in logarithmic time ($O(\log N)$) relative to the number of subtitles in the track.
- **Precision Grounding**: The function MUST continue to accurately identify the active subtitle even if the player timestamp lands slightly outside the nominal `[start_time, end_time]` range (e.g., in the gap between two subtitles). It should return the index of the subtitle whose boundary is nearest to the current `time_pos`.
- **Deduplication**: There SHALL be only one definition of `get_center_index` in `lls_core.lua`.

## Verification
- Load a large subtitle file (>5000 lines).
- Verify CPU usage remains stable during playback.
- Pause in the gap between two subtitles and verify that the nearest subtitle is correctly highlighted as active.
