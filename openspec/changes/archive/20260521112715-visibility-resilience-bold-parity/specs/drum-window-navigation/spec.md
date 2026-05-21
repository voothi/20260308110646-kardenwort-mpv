## ADDED Requirements

### Requirement: Interactive Visibility Resilience
The system's FSM visibility checks for interactive keybindings inside the Drum Window (such as tooltip toggle, pairing, adding to database, search, and copy) SHALL bypass master subtitle visibility restrictions. They MUST execute normally even when master subtitle visibility is toggled OFF (`FSM.native_sub_vis` is false).

#### Scenario: Tooltip toggle with subtitles OFF inside Drum Window
- **WHEN** the user is inside the Drum Window (`FSM.DRUM_WINDOW ~= "OFF"`)
- **AND** master subtitle visibility is toggled OFF (`FSM.native_sub_vis` is false)
- **AND** the user triggers the tooltip toggle command (key `e`)
- **THEN** the system SHALL successfully display the dictionary tooltip instead of aborting and showing "X"

#### Scenario: Interactive action outside Drum Window with subtitles OFF
- **WHEN** the user is outside the Drum Window (`FSM.DRUM_WINDOW == "OFF"`)
- **AND** master subtitle visibility is toggled OFF (`FSM.native_sub_vis` is false)
- **AND** the user triggers an interactive command (such as key `e`)
- **THEN** the system SHALL show "X" and abort the command
