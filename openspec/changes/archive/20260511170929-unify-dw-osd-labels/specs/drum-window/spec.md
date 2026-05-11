## ADDED Requirements

### Requirement: Unified Drum Window Management Inscriptions
The system SHALL provide consistent feedback when global keys that are managed or suppressed by the Drum Window are pressed.

#### Scenario: Pressing managed global keys in DW mode
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** the user presses any of the following keys: `x`, `Shift+x`, `c`, `Shift+c`, `Shift+f`
- **THEN** the system SHALL display a "X" OSD message.
- **AND** the default action for these keys SHALL be suppressed.

### Requirement: Simplified Drum Window Status Feedback
The Drum Window status message SHALL be concise and focused on the active state of the window.

#### Scenario: Triggering DW-blocked positioning controls
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** the user attempts to adjust subtitle positioning (e.g., `r`, `t`, `R`, `T`)
- **THEN** the system SHALL display "X".
- **AND** the " (Position Locked)" suffix SHALL be removed.

### Requirement: Mode Toggle OSD Feedback
The system SHALL provide clear OSD feedback when toggling primary modes.

#### Scenario: Toggling Drum Window
- **WHEN** the Drum Window is toggled ON
- **THEN** the system SHALL display "Drum Window: ON".
- **WHEN** the Drum Window is toggled OFF
- **THEN** the system SHALL display "Drum Window: OFF".
