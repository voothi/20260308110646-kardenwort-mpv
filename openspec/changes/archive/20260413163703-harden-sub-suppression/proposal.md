## Why

Native subtitles occasionally "leak" and become visible while the Drum Window is open, overlapping with the UI. This happens because the periodic suppression logic in the master tick loop is currently disabled when the Drum Window is active, allowing platform-triggered visibility resets (like track selection) to persist.

## What Changes

- **Harden Suppression Logic**: Refactor `master_tick` to ensure that native subtitle visibility is suppressed regardless of whether standard Drum Mode or the Drum Window is active.
- **Global Visibility Enforcement**: Move the "hammer down" logic for `sub-visibility` and `secondary-sub-visibility` to a position where it protects the Drum Window UI from overlapping native text.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window`: Visibility management requirements must be tightened to ensure exclusive UI focus.
- `subtitle-rendering`: Suppression rules should be unified to handle complex state transitions between OSD-SRT and the Drum Window.

## Impact

- `lls_core.lua`: The `master_tick` FSM logic and `update_media_state` track change handling.
