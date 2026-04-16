## Why

In Standard and Drum Mode (C), subtitles often remain gray (dimmed) when scrolling through them using the 'a' and 'd' keys, even if the player is technically paused at the start of the subtitle. This regression occurs because the rendering logic uses a strict range check that fails when MPV's seek positioning lands a few milliseconds before the official subtitle start time due to floating-point precision.

## What Changes

- Update the `draw_drum` rendering path to use a more robust "active" state detection.
- Align the highlighting behavior of Standard and Drum modes with the Drum Window's "centered-line" highlighting logic.
- Ensure that active subtitles are consistently highlighted white during navigation and playback, even across small subtitle gaps.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `subtitle-rendering`: Relax strict range checks to ensure active highlighting is maintained during precise seek operations and navigation.

## Impact

- `scripts/lls_core.lua`: Modification of the `draw_drum` and `format_sub` logic to handle precision-aware active states.
