## ADDED Requirements

### Requirement: Exclusive UI Visibility
The Drum Window SHALL maintain exclusive visibility over the active subtitle information, ensuring that native mpv subtitles do not overlap or leak through the UI regardless of media state changes or external property resets.

#### Scenario: Persistent Suppression During Track Selection
- **WHEN** the Drum Window is active (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** a subtitle track change or media state update occurs (e.g., SID change)
- **THEN** the system SHALL immediately ensure and maintain that `sub-visibility` and `secondary-sub-visibility` are set to `false`.
- **AND** native subtitle rendering SHALL NOT be restored until the Drum Window is explicitly closed.
