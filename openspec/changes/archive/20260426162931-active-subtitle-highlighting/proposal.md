## Why

Language learners using Drum Mode or Normal Mode with SRT OSD currently lack the rich word-level interactivity and Anki highlighting consistency found in the Drum Window. This change bridges that gap by enabling the same "active" word highlighting and mouse interactivity for primary and secondary subtitles during playback, significantly improving the immersion and efficiency of the language acquisition workflow.

## What Changes

- Enable "active" word highlighting (Cursor, Selection, Anki DB hits) for `drum_osd` (used in Drum Mode and SRT OSD mode).
- Implement high-precision hit-testing for `drum_osd` to allow mouse selection of words during playback.
- Add mouse event listeners to Drum Mode and SRT OSD mode to support selection, tooltips, and Anki additions.
- Ensure OSD interactivity respects `sub-pos` and `secondary-sub-pos` configuration hotkeys by dynamically recalculating hit-zones.
- **BREAKING**: Native subtitle interaction (if any existed via other scripts) will be fully superseded by the LLS OSD interaction when Drum Mode or SRT OSD is active.

## Capabilities

### New Capabilities
- `active-osd-interactivity`: High-precision hit-testing and event handling for dynamic OSD subtitles, enabling mouse interaction on moving video overlays.

### Modified Capabilities
- `anki-highlighting`: Extending database-driven word highlighting to standard OSD subtitles in Normal Mode.
- `dw-mouse-selection-engine`: Generalizing the Drum Window selection logic to support the dynamic, centered layouts used in Drum Mode and SRT OSD rendering.

## Impact

- `scripts/lls_core.lua`: Significant updates to the OSD rendering loop and mouse event handling logic.
- `input.conf`: No changes required, uses existing `dw_key_*` bindings.
- `script-opts/lls.conf`: New options to toggle OSD interactivity independent of the Drum Window.
