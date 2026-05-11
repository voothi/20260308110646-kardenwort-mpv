## ADDED Requirements

### Requirement: Unified Drum Window Management Inscriptions
The system SHALL provide consistent feedback when global keys that are managed or suppressed by the Drum Window are pressed.

#### Scenario: Pressing managed global keys in DW mode
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** the user presses any of the following keys: `x`, `Shift+x`, `c`, `Shift+c`, `Shift+f`
- **THEN** the system SHALL display a "Managed by Drum Window" OSD message.
- **AND** the default action for these keys SHALL be suppressed.

### Requirement: Simplified Drum Window Status Feedback
The Drum Window status message SHALL be concise and focused on the active state of the window.

#### Scenario: Triggering DW-blocked positioning controls
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** the user attempts to adjust subtitle positioning (e.g., `r`, `t`, `R`, `T`)
- **THEN** the system SHALL display "Drum Window: Active".
- **AND** the " (Position Locked)" suffix SHALL be removed.
