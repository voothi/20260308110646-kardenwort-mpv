## ADDED Requirements

### Requirement: Deterministic Navigation Intent Snapshot
The system SHALL resolve a single navigation intent snapshot before applying DW/DM pointer movement logic.

#### Scenario: Snapshot is resolved once per intent
- **WHEN** a navigation intent enters DW/DM pointer handling via `UP`, `DOWN`, `LEFT`, or `RIGHT`
- **THEN** the handler SHALL resolve one snapshot containing active-line context and pointer-state context
- **AND** all movement decisions for that intent SHALL use this snapshot instead of re-resolving active context mid-intent.

#### Scenario: Snapshot fallback order
- **WHEN** active-line context is resolved for an intent snapshot
- **THEN** resolution SHALL prioritize a valid synchronized playback index source
- **AND** if the primary source is unavailable, a secondary synchronized source SHALL be used
- **AND** if no synchronized source is available, the current standing cursor line SHALL be used as safe fallback.

### Requirement: Event-Type Gating for Pointer Activation
The system SHALL gate arrow-key events by event type and pointer activation state without time-based magic guards.

#### Scenario: Key-up does not move pointer
- **WHEN** a complex navigation binding emits an `up` event
- **THEN** pointer movement SHALL NOT be applied for that event.

#### Scenario: Null-pointer activation consumes one entry step
- **WHEN** pointer state is null (`DW_CURSOR_WORD = -1`) and a navigation intent starts
- **THEN** the first accepted activation event SHALL consume exactly one activation step
- **AND** immediate duplicate repeat events for that activation SHALL NOT produce additional unintended movement.

### Requirement: Deterministic Desync Rebase Continuation
The system SHALL deterministically rebase stale manual pointer state to current playback context before continuing user navigation intent.

#### Scenario: Rebase stale manual pointer without Shift
- **WHEN** pointer is manual-active on a non-active line during live playback
- **AND** user navigates with `UP`, `DOWN`, `LEFT`, or `RIGHT` without Shift
- **THEN** pointer source SHALL rebase to the current active subtitle line first
- **AND** the same user intent SHALL continue from that rebased source without requiring extra `Esc`.
