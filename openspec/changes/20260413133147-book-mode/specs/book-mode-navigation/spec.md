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

### Requirement: Interaction Supression in Book Mode
When the system is in Book Mode, standard subtitle navigation interactions and vocabulary selection interactions SHALL NOT exit or collapse the Drum Window state back into normal Drum Mode.

#### Scenario: Subtitle scrolling with Book Mode ON
- **WHEN** the user is in Book Mode (`is_book_mode == true` and `state.drum_window == true`)
- **AND** the user navigates subtitles using `a` (previous) or `d` (next) keys
- **THEN** the subtitle position SHALL seek to the appropriate line 
- **AND** the active rendering mode SHALL REMAIN as Drum Window mode exclusively.

#### Scenario: Vocabulary selection with Book Mode ON
- **WHEN** the user is in Book Mode (`is_book_mode == true` and `state.drum_window == true`)
- **AND** the user double-clicks the Left Mouse Button (`mbtn_left_dbl`)
- **THEN** the vocabulary highlight SHALL register correctly 
- **AND** the active rendering mode SHALL REMAIN as Drum Window mode exclusively.
