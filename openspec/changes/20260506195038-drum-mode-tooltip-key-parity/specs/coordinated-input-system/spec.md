## ADDED Requirements

### Requirement: Coordinated Tooltip Keys Across Drum and DW
The coordinated key system SHALL route configured tooltip keys to the correct mode-specific tooltip handler while preserving a single logical key configuration surface.

#### Scenario: Drum Mode routing
- **WHEN** a configured tooltip key is triggered and `FSM.DRUM == "ON"` with `FSM.DRUM_WINDOW == "OFF"`
- **THEN** the key SHALL dispatch to the Drum Mode tooltip handler
- **AND** it SHALL NOT invoke Drum Window tooltip handlers in the same event.

#### Scenario: Drum Window routing
- **WHEN** a configured tooltip key is triggered and `FSM.DRUM_WINDOW == "DOCKED"`
- **THEN** the key SHALL dispatch to Drum Window tooltip handlers according to existing DW contracts.

### Requirement: Layout-Parity Tooltip Triggers
Configured multi-key lists for tooltip actions SHALL preserve keyboard-layout parity in Drum Mode.

#### Scenario: EN/RU tooltip key parity
- **WHEN** tooltip trigger options include multiple physical-key variants for the same logical action
- **THEN** each configured key variant SHALL activate the same Drum tooltip behavior.
