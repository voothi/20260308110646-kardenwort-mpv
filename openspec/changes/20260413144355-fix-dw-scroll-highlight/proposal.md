## Why

Scrolling in Drum Window mode currently disrupts text selection and word highlighting. Previously, wheel scrolling events manually cleared the word-cursor state and failed to synchronize the mapping after the viewport shifted. This created two problems:
1.  **Disruption**: Active selections were lost or "cleared" on scroll.
2.  **Sticking/Snapping**: Attempts to synchronize the cursor during scrolling initially revealed "sticking" effects where finished selections would expand to match the mouse, or the active word (yellow highlight) would unexpectedly snap to the mouse pointer during a scroll.

## What Changes

- **Synchronized Scroll Highlight**: Update `cmd_dw_scroll` to maintain and refresh the word-cursor state during viewport shifts.
- **Drag-Exclusive Synchronization**: Harden the synchronization logic to ensure the logical cursor only follows the mouse during an active drag operation.
- **Selection & Hover Protection**: Ensure that "finished" selections and the stationary yellow active-word highlight remain correctly anchored to their text indices and do not snap to the mouse pointer during scrolling unless the user is actively selecting.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window`: Update mouse interaction requirements to ensure scrolling preserves selection stability and prevents unintended hover snapping.
- `lls-mouse-input`: Refine the event-driven hit-test synchronization to be state-aware (dragging vs. stationary).

## Impact

- `scripts/lls_core.lua`: Significant hardening of `cmd_dw_scroll` and introducing `dw_sync_cursor_to_mouse` with state-aware guards.
- Visual continuity and interaction fidelity in Drum Window mode.
