## MODIFIED Requirements

### Requirement: Stationary Viewport (Frozen Scroll) in Book Mode
When in Book Mode, the system SHALL decouple the viewport center from the playback time, ensuring the list remains stationary during playback and navigation.

#### Scenario: Playback progression in Book Mode
- **WHEN** the system is in Book Mode
- **AND** the video plays forward
- **THEN** the active subtitle highlight SHALL move
- **BUT** the viewport (`FSM.DW_VIEW_CENTER`) SHALL NOT scroll automatically.

#### Scenario: Manual navigation in Book Mode
- **WHEN** the user seeks via `a`/`d` or double-click to select a word
- **THEN** the video SHALL seek to the target line
- **AND** the manual cursor focus (`FSM.DW_CURSOR_LINE`) SHALL synchronize with the target line (provided no manual range or word selection is active, i.e., `ANCHOR_LINE == -1`)
- **BUT** the viewport center SHALL REMAIN static at its current scrolled position, preventing the "jump" back to center.

### Requirement: Selection Persistence During Manual Navigation
The system SHALL ensure that any active Drum Window selection (yellow highlight) is preserved when navigating between subtitles using manual seek keys (`a`/`d`), regardless of whether Book Mode is active.

#### Scenario: Selection stability during manual seek
- **WHEN** a word or text range is highlighted in yellow (defined by `ANCHOR_LINE ~= -1`)
- **AND** the user presses `a` or `d` to seek to a target subtitle
- **THEN** the video SHALL seek to the target time
- **AND** the yellow highlight SHALL NOT be cleared or reset to gray (standard state)
- **AND** the manual cursor focus (`FSM.DW_CURSOR_LINE`) SHALL remain on the existing selection
- **AND** the system SHALL maintain the existing `ANCHOR` point, allowing the selection to persist or expand naturally.
