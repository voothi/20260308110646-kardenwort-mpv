## ADDED Requirements

### Requirement: Book Mode State Management
The system SHALL maintain a "Book Mode" state that determines whether the Window Drum (`w`) mode should be locked tightly, preventing interaction-based dismissal.
The system SHALL allow this mode to be toggled at runtime using the `b` (or `и` in Russian) key, and it SHALL fallback to an initial state configured via `mpv.conf`.

#### Scenario: Toggling Book Mode via hotkey
- **WHEN** the user presses `b` (or `и`)
- **THEN** the system SHALL toggle the internal Book Mode boolean state
- **AND** the system SHALL immediately engage Drum Window mode if Book Mode is turned to ON.

#### Scenario: Configuration initialization
- **WHEN** the script initializes
- **THEN** the system SHALL read the `book_mode` boolean parameter from `mpv.conf` (under the script-opts grouping) to define the initial lock state.

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
- **BUT** the viewport center SHALL REMAIN static at its current scrolled position, preventing the "jump" back to center.
