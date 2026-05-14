## MODIFIED Requirements

### Requirement: Canonical DM/DW State Variables
The system SHALL utilize the following canonical state variables to ensure navigational traceability:
- `DW_POINTER_FSM` (canonical FSM state: `POINTER_NULL_FOLLOW`, `POINTER_ACTIVE_MANUAL`, `POINTER_RANGE_ACTIVE`),
- `DW_FOLLOW_PLAYER` (white-line follow-leading gate),
- `DW_ACTIVE_LINE` (current playback subtitle index),
- `DW_CURSOR_LINE` (standing yellow line context),
- `DW_CURSOR_WORD` (yellow pointer token; `-1` means no active pointer),
- `DW_ANCHOR_LINE` and `DW_ANCHOR_WORD` (range anchor),
- `DW_VIEW_CENTER` (manual/book viewport center),
- `DW_SEEKING_MANUALLY` and `DW_SEEK_TARGET` (manual seek transit state).

#### Scenario: State Variable Verification
- **WHEN** auditing the internal FSM state
- **THEN** all navigational intents SHALL be traceable to the canonical variables listed above.

### Requirement: Null-Pointer Activation Source
The system SHALL ensure that after pointer clear, the first activation resolves from current runtime context.
- **WHEN** the pointer is cleared via Esc or Seek
- **THEN** the first activation SHALL resolve from the current runtime context to prevent stale history drift.

#### Scenario: First activation after final Esc
- **WHEN** pointer state is null (`DW_CURSOR_WORD = -1`) and user activates navigation
- **THEN** source line resolution SHALL prioritize:
1. current `EVENT_SNAPSHOT` active line,
2. valid standing `DW_CURSOR_LINE`,
3. otherwise active `DW_ACTIVE_LINE`.
- **AND** `UP` SHALL use middle-word entry if playback is active
- **AND** `DOWN` SHALL use directional visual-line entry semantics
- **AND** `LEFT`/`RIGHT` SHALL use line-edge token entry semantics.
