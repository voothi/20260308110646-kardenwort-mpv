## ADDED Requirements

### Requirement: Selection Persistence During Manual Navigation
The system SHALL ensure that any active Drum Window selection (yellow highlight) is preserved when navigating between subtitles using manual seek keys (`a`/`d`), regardless of whether Book Mode is active.

#### Scenario: Selection stability during manual seek
- **WHEN** a word or text range is highlighted in yellow
- **AND** the user presses `a` or `d` to seek to a different subtitle
- **THEN** the video SHALL seek to the target time
- **AND** the yellow highlight SHALL NOT be cleared or reset to gray (standard state)
- **AND** the system SHALL maintain the existing `ANCHOR` point, allowing the selection to persist or expand naturally.
