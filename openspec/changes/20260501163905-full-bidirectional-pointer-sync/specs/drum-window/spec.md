# Delta: Drum Window (Bidirectional Sync)

## MODIFIED Requirements

### Requirement: Drum Window Selection Priority
The system SHALL ensure that any active word pointer (Yellow Highlight) is preserved when opening the Drum Window.

#### Scenario: Opening Drum Window with active Pointer
- **GIVEN** a word is already highlighted in Drum Mode (C) or Regular SRT mode.
- **WHEN** the user opens the Drum Window (Mode W).
- **THEN** the system SHALL NOT reset the pointer.
- **AND** the word SHALL remain highlighted at the same index in the window.
- **AND** the window viewport (`DW_VIEW_CENTER`) SHALL immediately jump to the line containing the pointer.
