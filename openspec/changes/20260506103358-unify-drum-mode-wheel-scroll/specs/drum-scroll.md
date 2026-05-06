## ADDED Requirements

### Requirement: Drum Mode Viewport Scrolling
The immersion engine SHALL allow the user to scroll the subtitle viewport in Drum Mode (on-screen subtitles) using the mouse wheel, without affecting the playback position.

#### Scenario: Manual Scrolling in Drum Mode
- **WHEN** Drum Mode is ON AND the mouse is hovering over a subtitle line
- **AND** the user spins the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL set `FSM.DW_FOLLOW_PLAYER` to `false`
- **AND** the system SHALL update `FSM.DW_VIEW_CENTER` based on the wheel direction
- **AND** the on-screen Drum Mode OSD SHALL immediately update to show the new viewport context.

### Requirement: Automated Scroll Reset
The immersion engine SHALL automatically resume following the player position when the user performs a seek or navigates to a new subtitle.

#### Scenario: Resetting Scroll via Seek
- **WHEN** `FSM.DW_FOLLOW_PLAYER` is `false` (manual scroll active)
- **AND** the user performs a seek via `a` or `d` keys
- **THEN** the system SHALL set `FSM.DW_FOLLOW_PLAYER` to `true`
- **AND** the system SHALL synchronize `FSM.DW_VIEW_CENTER` with the new active subtitle index.
