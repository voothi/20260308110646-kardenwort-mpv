## ADDED Requirements

### Requirement: OSD Hit-Testing
The system SHALL implement a hit-testing mechanism for `drum_osd` that correctly identifies which word and subtitle index the mouse is hovering over, regardless of the screen resolution or aspect ratio.

#### Scenario: Mouse hovering over a word in Drum Mode
- **WHEN** Drum Mode is ON and the user hovers the mouse over a specific word in the OSD
- **THEN** the system SHALL identify the correct subtitle index and logical word index for that word

### Requirement: OSD Mouse Interaction
The system SHALL support mouse click and double-click events on the `drum_osd` overlay to trigger selection and seeking, mimicking the behavior of the Drum Window.

#### Scenario: Double-clicking a word in standard OSD
- **WHEN** standard OSD subtitles are active and the user double-clicks a word
- **THEN** the system SHALL seek to the start time of that subtitle and set the cursor focus to that word

### Requirement: Dynamic Position Synchronization
The OSD interaction logic SHALL automatically synchronize with changes to `sub-pos` and `secondary-sub-pos` without requiring a script reload.

#### Scenario: Adjusting subtitle position via hotkey
- **WHEN** the user presses `r` or `t` to move the subtitles vertically
- **THEN** the system SHALL immediately update the hit-zone metadata to reflect the new visual position of the words
