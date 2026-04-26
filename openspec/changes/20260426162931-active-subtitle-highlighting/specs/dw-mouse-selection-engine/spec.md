## MODIFIED Requirements

### Requirement: Unified Layout Hit-Testing
The system SHALL use a pre-calculated layout table to ensure 1:1 mapping between rendered text and mouse click coordinates across all interactive overlays (Drum Window and Drum Mode/OSD).

#### Scenario: Clicking a wrapped word in the Drum Window
- **WHEN** the user clicks on a word that has been wrapped to a new line in the Drum Window
- **THEN** the system SHALL correctly identify the word index by referencing the `dw_build_layout` coordinate table.

#### Scenario: Clicking a word in Drum Mode OSD
- **WHEN** the user clicks on a word in the Drum Mode OSD overlay
- **THEN** the system SHALL correctly identify the word index by referencing the dynamic `drum_osd` coordinate table.
