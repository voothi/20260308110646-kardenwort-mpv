## MODIFIED Requirements

### Requirement: Strict Mode Switching Bindings
The system SHALL provide dedicated key bindings for activating Drum Mode and Drum Window, ensuring predictable state transitions.

#### Scenario: Activate Drum Mode
- **WHEN** the `x` (or `ч`) key is pressed
- **THEN** the system SHALL activate Drum Mode (DM)
- **AND** it SHALL deactivate Drum Window (DW) if active

#### Scenario: Activate Drum Window
- **WHEN** the `z` (or `я`) key is pressed
- **THEN** the system SHALL activate Drum Window (DW)
- **AND** it SHALL deactivate Drum Mode (DM) if active

### Requirement: Layout-Agnostic Mode Toggles
Mode switching commands MUST support both English and Russian keyboard layouts for the primary activation keys.

#### Scenario: Russian Layout Activation
- **WHEN** the system is in Russian layout and `я` is pressed
- **THEN** the Drum Window mode MUST be activated as if `z` was pressed
