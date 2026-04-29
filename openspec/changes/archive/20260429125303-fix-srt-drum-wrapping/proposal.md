# Proposal: Fix Long SRT Subtitle Wrapping in Drum/OSD Mode

## Problem
Currently, long SRT subtitles in `drum (c)` mode (and regular OSD rendering mode) do not wrap, causing them to extend beyond the screen boundaries. This was introduced when switching to manual OSD rendering using the `ass-events` overlay, which lacks automatic wrapping when using explicit positioning (`{\pos}`) and non-wrapping style tags (`{\q2}`).

## Objectives
- Implement automatic wrapping for long subtitle lines in the main OSD rendering path (`draw_drum`).
- Ensure that the wrapped lines remain centered and correctly spaced.
- Maintain accurate hit-testing (interactivity) for wrapped words.

## Proposed Changes
- Refactor `draw_drum` to support multi-line layout per subtitle.
- Update `calculate_osd_line_meta` to handle wrapping and return multi-line geometry.
- Share wrapping logic between the "Drum Window" and the main OSD renderer where possible.

## User Impact
Users will be able to read long SRT subtitles (especially those manually grouped into long sentences) without them bleeding off the screen, while keeping the premium OSD styling and interactivity features.
