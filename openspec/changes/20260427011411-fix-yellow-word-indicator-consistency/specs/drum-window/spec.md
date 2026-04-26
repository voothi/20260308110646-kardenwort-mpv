## ADDED Requirements

### Requirement: Cross-Mode Cursor Synchronization
The yellow word indicator state must be synchronized with the currently active playback line regardless of whether the Drum Window is open or closed, as long as Drum Mode is active.

#### Scenario: Escape synchronization in Mode C
- **WHEN** Drum Mode (Mode C) is ON and the Drum Window (Mode W) is OFF
- **WHEN** A yellow word indicator is visible and the user presses `Esc`
- **THEN** The indicator must disappear immediately
- **THEN** `FSM.DW_CURSOR_LINE` must be set to the currently active subtitle line index

#### Scenario: Arrow navigation after Escape in Mode C
- **WHEN** The indicator has been cleared with `Esc` in Mode C
- **WHEN** The user presses `Up`
- **THEN** A yellow word indicator must appear in the middle of the subtitle line immediately above the previously active line

#### Scenario: Horizontal arrow navigation after Escape in Mode C
- **WHEN** The indicator has been cleared with `Esc` in Mode C
- **WHEN** The user presses `Right`
- **THEN** The first word of the active subtitle line must be highlighted
