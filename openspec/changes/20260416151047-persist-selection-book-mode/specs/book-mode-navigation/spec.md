## ADDED Requirements

### Requirement: Selection Persistence During Manual Navigation
The system SHALL ensure that any active Drum Window selection (yellow highlight) is preserved when navigating between subtitles using manual seek keys (`a`/`d`), regardless of whether Book Mode is active.

#### Scenario: Selection stability during manual seek
- **WHEN** a word or text range is highlighted in yellow
- **AND** the user presses `a` or `d` to seek to a target subtitle
- **THEN** the video SHALL seek to the target time
- **AND** the yellow highlight SHALL NOT be cleared or reset to gray (standard state)
- **AND** the system SHALL maintain the existing `ANCHOR` point, allowing the selection to persist or expand naturally.

### Requirement: Selection-Aware Tooltip Logic
The system SHALL ensure that the tooltip remains focused on the active playback subtitle during and immediately after playback (e.g., in an autopause state). The tooltip SHALL ONLY switch back to the manual selection cursor (yellow pointer) when the user actively interacts with it.

#### Scenario: Tooltip remains on active subtitle after autopause
- **GIVEN** a selection (yellow highlight) is present on Line 10
- **AND** the tooltip is currently following the active playback at Line 15
- **WHEN** the player reaches the end of the subtitle and autopauses
- **THEN** the tooltip SHALL remain stable at Line 15
- **AND** it SHALL NOT automatically jump back to the yellow highlight at Line 10.

#### Scenario: Tooltip switches to selection on manual interaction
- **GIVEN** the player is paused and the tooltip is currently following the active subtitle at Line 15
- **WHEN** the user manually moves the selection pointer (e.g., via arrow keys or a mouse click)
- **THEN** the tooltip SHALL immediately switch to follow the selection pointer's new location.
