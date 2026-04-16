## ADDED Requirements

### Requirement: Selection Persistence in Book Mode
The system SHALL ensure that any active Drum Window selection (yellow highlight) is preserved when navigating between subtitles using manual seek keys (`a`/`d`) while Book Mode is enabled.

#### Scenario: Selection stability during manual seek
- **WHEN** Book Mode is ON
- **AND** a word or text range is highlighted in yellow
- **AND** the user presses `a` or `d` to seek to a different subtitle
- **THEN** the video SHALL seek to the target time
- **AND** the yellow highlight SHALL NOT be cleared or reset to gray
