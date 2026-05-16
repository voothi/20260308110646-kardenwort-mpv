## MODIFIED Requirements

### Requirement: Drum Mode Visibility Master
The Drum Mode (Mode C) toggle SHALL control the rendering style (single-line vs multi-line context), but SHALL respect the global subtitle visibility toggle (`s` key).
- **Secondary Only Mode**: The system SHALL support a state where only secondary subtitles are rendered, while maintaining primary track synchronization.

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
- **THEN** the system SHALL toggle the FSM visibility intent (`FSM.native_sub_vis` and `FSM.native_sec_sub_vis`)
- **AND** the Drum Window SHALL remain open and continue rendering its own OSD surface while active
- **AND** when the Drum Window is closed, native subtitle visibility restoration SHALL reflect the updated FSM intent.

#### Scenario: Cycling to Secondary Only Mode
- **WHEN** the user cycles through visibility states
- **THEN** the system SHALL enter a state where `FSM.SEC_ONLY_MODE` is true
- **AND** the OSD SHALL render only the secondary subtitle track
- **AND** the primary track SHALL remain active in the FSM but hidden from the OSD.
