## MODIFIED Requirements

### Requirement: Drum Mode Visibility Master
The Drum Mode (Mode C) toggle SHALL control the rendering style (single-line vs multi-line context), but SHALL respect the global subtitle visibility toggle (`s` key).

#### Scenario: Hiding Subtitles in Drum Mode
- **GIVEN** Drum Mode is toggled ON and subtitles are visible
- **WHEN** the user toggles native subtitle visibility OFF (using `s` or `ы`)
- **THEN** the custom OSD rendering SHALL immediately become invisible.

#### Scenario: Showing Subtitles in Drum Mode
- **GIVEN** Drum Mode is toggled ON and subtitles are hidden
- **WHEN** the user toggles native subtitle visibility ON (using `s` or `ы`)
- **THEN** the custom OSD rendering SHALL immediately become visible using Drum Mode styling.

#### Scenario: Visibility Toggle in Drum Window
- **GIVEN** the Drum Window (Mode W) is active
- **WHEN** the user presses `s` or `ы`
- **THEN** the system SHALL NOT change the subtitle visibility state
- **AND** it SHALL display a warning OSD indicating that visibility is managed by the Drum Window.
