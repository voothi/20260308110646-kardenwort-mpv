## ADDED Requirements

### Requirement: Standard Command Layout Symmetry
The system SHALL map standard player commands to their Russian keyboard layout equivalents to provide a seamless experience without manual layout switching.

#### Scenario: Muting in Russian layout
- **WHEN** the user presses the `ь` key
- **THEN** the player SHALL toggle the mute state (equivalent to `m`).

#### Scenario: Stepping frames in Russian layout
- **WHEN** the user presses `ю` or `б`
- **THEN** the player SHALL step forward or backward by one frame (equivalent to `.` and `,`).
