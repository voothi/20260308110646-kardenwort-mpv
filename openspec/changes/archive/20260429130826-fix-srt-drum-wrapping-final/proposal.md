# Proposal: Automatic SRT Subtitle Wrapping for OSD Rendering

## Problem
Long SRT subtitles in `drum (c)` and regular OSD modes were bleeding off the screen edges. This occurred because the script used a fixed-width single-line rendering model with the `{\q2}` (no-wrap) ASS tag. Manual sentence grouping by users exacerbated this issue.

## Objectives
- Introduce a robust, manual word-wrapping engine for on-screen subtitles.
- Maintain pixel-perfect hit-testing (interactivity) for wrapped words.
- Ensure consistent vertical layout between active and context subtitle lines.

## Proposed Changes
- Implement a `wrap_tokens` utility to calculate line breaks based on visual width heuristics.
- Refactor `calculate_osd_line_meta` to support multi-line geometry objects.
- Update `draw_drum` to flatten multi-line subtitles into individual visual hit-zones.
- Ensure explicit source-level newlines (`\n`) are preserved and handled as forced breaks.

## User Impact
Users can now consume long, sentence-grouped subtitles in the premium OSD mode without loss of context or overlapping. Interactive features like word-level highlighting remain fully functional on wrapped lines.
