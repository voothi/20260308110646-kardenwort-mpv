## Why

This change formalizes the Track Scrolling Keys introduced in Release v1.2.22. In normal mode, the arrow keys are used for 2-second track scrolling. However, when the Drum Window (Static Reading Mode) is active, these keys are hijacked for text navigation. This update introduces alternative hotkeys (`Shift+A` and `Shift+D`) to ensure that precise seeking remains accessible at all times, regardless of the active viewing mode.

## What Changes

- Implementation of **Mode-Independent Seeking**: Adding `Shift+A` and `Shift+D` as hotkeys for exact 2-second seeking (`seek -2 exact` and `seek 2 exact`).
- Expansion of **Layout-Agnostic Seeking**: Mapping Russian keyboard layout equivalents (`Ф` and `В`) to the new seek commands to prevent input friction during immersion.
- Conflict resolution: These new keys provide a dedicated path for time-based navigation that does not conflict with the Drum Window's viewport scrolling.

## Capabilities

### New Capabilities
- `track-scrolling-accessibility`: A redundant navigation strategy that ensures critical playback controls (like seeking) remain accessible even when primary keys are repurposed by specialized UI modes.
- `layout-agnostic-seeking`: Consistent seek controls that operate symmetrically across English and Russian keyboard layouts.

### Modified Capabilities
- None (Incremental configuration update).

## Impact

- **Operational Continuity**: Users can now adjust video position without closing the Drum Window.
- **Workflow Efficiency**: Eliminates the need for layout switching to perform precise 2-second seeks.
- **Reliability**: Guaranteed accessibility of core playback controls across all operational states of the acquisition suite.
