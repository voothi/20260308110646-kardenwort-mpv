## Why

Scrolling in Drum Window mode currently disrupts text selection and word highlighting. This occurs because wheel scrolling events manually clear the word-cursor state and fail to synchronize the mouse-to-text mapping after the viewport shifts. This creates a jerky, inconsistent experience where users lose their selection or active highlight when using the mouse wheel.

## What Changes

- **Synchronized Scroll Highlight**: Update `cmd_dw_scroll` to maintain the word-cursor state instead of clearing it.
- **Immediate Hit-Test Refresh**: Force a mouse hit-test recalculation immediately after a wheel scroll to ensure the highlight/selection updates with the new viewport state.
- **Selection Continuity**: Ensure that active drag-selection remains stable and visually correct when the viewport is scrolled via the mouse wheel.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window`: Update mouse interaction requirements to ensure scrolling preserves selection state and highlight synchronization.
- `lls-mouse-input`: Refine how mouse scroll events interact with the active window hit-testing.

## Impact

- `scripts/lls_core.lua`: Modification to `cmd_dw_scroll` and surrounding mouse logic.
- Visual continuity in Drum Window mode.
