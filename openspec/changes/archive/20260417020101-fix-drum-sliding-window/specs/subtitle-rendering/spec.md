## ADDED Requirements

### Requirement: Sliding-Window Boundary Filling
The system SHALL maintain a full range of visible context subtitles even when the active subtitle is near the start or end of the track, provided sufficient subtitles exist in the track.

#### Scenario: Reaching the end of the track
- **GIVEN** a subtitle track with 100 entries and a window size of 15 lines
- **WHEN** the logical center position is at index 100
- **THEN** the system SHALL display subtitle entries from index 86 to 100.
- **AND** the active subtitle (index 100) SHALL be positioned at the bottom of the rendered block.

#### Scenario: Reaching the start of the track
- **GIVEN** a subtitle track with 100 entries and a window size of 15 lines
- **WHEN** the logical center position is at index 1
- **THEN** the system SHALL display subtitle entries from index 1 to 15.
- **AND** the active subtitle (index 1) SHALL be positioned at the top of the rendered block.

#### Scenario: Visual Consistency during Seek/Scroll
- **WHEN** navigating near track boundaries using the mouse wheel or navigation keys ('a', 'd')
- **THEN** the total number of rendered lines SHALL remain constant (matching `dw_lines_visible` or `context_lines` * 2 + 1) to prevent vertical shifting of the OSD block on the screen.
