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

### Requirement: Paged Viewport (Auto-Scrolling) in Book Mode
When in Book Mode, the system SHALL automatically scroll the viewport in "pages" during playback to keep the active subtitle visible while maximizing reading context.

#### Scenario: Playback progression in Book Mode
- **WHEN** the system is in Book Mode
- **AND** the video plays forward
- **THEN** the active subtitle highlight SHALL move
- **AND** when the highlight reaches the bottom margin, the viewport SHALL jump forward so the active line is at the top margin.

#### Scenario: Manual navigation in Book Mode
- **WHEN** the user seeks via `a`/`d`
- **THEN** the video SHALL seek to the target line
- **AND** the viewport SHALL use "push" scrolling to keep the line visible
- **AND** the yellow cursor highlight SHALL follow the seek target.

### Requirement: Selection Persistence During Manual Navigation
The system SHALL ensure that any active Drum Window selection (yellow highlight) is preserved when navigating between subtitles using manual seek keys (`a`/`d`), regardless of whether Book Mode is active.

#### Scenario: Selection stability during manual seek
- **WHEN** a word or text range is highlighted in yellow
- **AND** the user presses `a` or `d` to seek to a target subtitle
- **THEN** the video SHALL seek to the target time
- **AND** the yellow highlight SHALL NOT be cleared or reset to gray (standard state)
- **AND** the system SHALL maintain the existing `ANCHOR` point, allowing the selection to persist or expand naturally.

### Requirement: Selection-Aware Tooltip Logic (Stabilization)
To ensure a fluid study workflow, the system SHALL prioritize the active playback context for tooltips during and immediately after subtitles are played, while allowing manual overrides.

#### Scenario: Tooltip remains on active subtitle after autopause
- **GIVEN** a selection (yellow highlight) is present on Line 10
- **AND** the tooltip is currently following the active playback at Line 15
- **WHEN** the player reaches the end of the subtitle and autopauses
- **THEN** the tooltip SHALL remain stable at Line 15 (last active context)
- **AND** it SHALL NOT automatically jump back to the stale selection at Line 10.

#### Scenario: Tooltip targeting reset on playback start
- **GIVEN** the player is paused and the tooltip is focused on a manual selection cursor
- **WHEN** the user starts playback (e.g. via spacebar)
- **THEN** the tooltip SHALL immediately switch to follow the active playback subtitle.

#### Scenario: Tooltip switches to selection on manual interaction
- **GIVEN** the player is paused and the tooltip is currently following the active subtitle
- **WHEN** the user manually moves the selection pointer (e.g., via arrow keys or a mouse click)
- **THEN** the tooltip SHALL immediately switch to follow the selection pointer's new location.

### Requirement: Anti-Stretching Selection Logic (Stability)
In Standard (Follow) Mode, the system SHALL ensure that active highlights remain fixed to their original text and do not "stretch" as the video advances.

#### Scenario: Fixed highlight during playback
- **GIVEN** a range is highlighted from Line 10 to Line 10 (Standard Mode)
- **WHEN** the video playback advances to Line 11
- **THEN** the selection cursor SHALL NOT follow the playback pointer
- **AND** the highlight SHALL remain strictly on Line 10, preventing it from expanding across multiple lines.

### Requirement: Selection Cleanup & Persistence Nuances
The system SHALL ensure that all intentional selections are stable and persistent, while avoiding "phantom" highlights during navigation.

- **Intentional Selections**: Any selection created via click or drag (including single words) SHALL create an anchor-based context (`ANCHOR_LINE ~= -1`). Such selections SHALL be stable (no stretching) and persistent during seeks in BOTH Book Mode and Standard Mode.
- **Pointer Cleanup**: In Standard (Follow) Mode, if there is NO active selection (e.g., following a double-click seek reset), the system SHALL clear the "naked" yellow cursor word during `a`/`d` seeks to preserve interface cleanliness.
- **Track Change Safety**: All selection and tooltip states SHALL be reset upon subtitle track reload to prevent Out-of-Bounds crashes.
