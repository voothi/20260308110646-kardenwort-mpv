## ADDED Requirements

### Requirement: Drum Mini z Tooltip Activation
The system SHALL provide tooltip interaction on the primary subtitle surface while Drum Mode is active, enabling a compact mini z-reel workflow without opening Drum Window.

#### Scenario: Trigger tooltip in Drum Mode
- **WHEN** `FSM.DRUM == "ON"`, `FSM.DRUM_WINDOW == "OFF"`, and the user executes a configured tooltip trigger key
- **THEN** the system SHALL resolve the focused word from Drum Mode primary hit-zones
- **AND** it SHALL render tooltip content for that word using the tooltip overlay pipeline.

### Requirement: Scope Exclusion for Book Mode
The Drum mini z tooltip workflow SHALL NOT require or modify Book Mode behavior.

#### Scenario: Book Mode remains unchanged
- **WHEN** Book Mode is enabled in Drum Window workflows
- **THEN** Drum mini z tooltip requirements SHALL not alter Book Mode key routing, selection semantics, or copy behavior.
