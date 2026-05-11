## Why

In the lower window of the main subtitles, the Right Mouse Button (RMB) behavior is inconsistent between Drum Mode (dm) and Drum Window (dw). In Drum Window, interactions work when clicking between lines, but in Drum Mode, the user must click strictly on the text, making interaction feel fragile and less intuitive.

## What Changes

- Refactor `drum_osd_hit_test` to support vertical proximity snapping, allowing mouse interactions (RMB for tooltips, LMB for selection) to work in the gaps between subtitle lines in Drum Mode.
- Align hit-testing logic of Drum Mode with the more permissive "snap-to-nearest-line" behavior of Drum Window.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `lls-mouse-input`: Update hit-testing requirements to allow vertical snapping in Drum Mode hit zones.

## Impact

- `scripts/lls_core.lua`: Modification of `drum_osd_hit_test` and potentially how `DRUM_HIT_ZONES` are populated or queried.
- Improved UX for mouse-driven translation and selection in Drum Mode.
