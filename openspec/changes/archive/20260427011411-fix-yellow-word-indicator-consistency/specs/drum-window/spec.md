## ADDED Requirements

### Requirement: Cross-Mode Cursor Synchronization
The yellow word indicator state must be synchronized with the currently active playback line regardless of whether the Drum Window is open or closed, as long as Drum Mode is active.

#### Scenario: Escape synchronization in Mode C
- **WHEN** Drum Mode (Mode C) is ON and the Drum Window (Mode W) is OFF
- **WHEN** A yellow word indicator is visible and the user presses `Esc`
- **THEN** The indicator must disappear immediately
- **THEN** `FSM.DW_CURSOR_LINE` must be set to the currently active subtitle line index

#### Scenario: Vertical arrow navigation after Escape
- **WHEN** The indicator has been cleared with `Esc`
- **WHEN** The user presses `Up` (or `Down`)
- **THEN** A yellow word indicator must appear in the middle (x=960) of the subtitle line immediately above (or below) the active line.

#### Scenario: Horizontal arrow navigation after Escape
- **WHEN** The indicator has been cleared with `Esc`
- **WHEN** The user presses `Right`
- **THEN** The first word of the active subtitle line must be highlighted.
- **WHEN** The user presses `Left`
- **THEN** The last word of the active subtitle line must be highlighted.

### Requirement: Independent Mode C Viewport
The cursor navigation in Mode C must not trigger viewport scrolling.

#### Scenario: Moving cursor in Mode C
- **WHEN** The user navigates the cursor with arrows in Mode C
- **THEN** The yellow indicator moves but the underlying subtitles stay fixed at the current video playback position.

### Requirement: Stability and Error Prevention
The system must not crash when toggling modes or updating the OSD.

#### Scenario: Opening Drum Window
- **WHEN** The user toggles the Drum Window (Mode W) ON
- **THEN** The window must initialize and render without Lua errors, even if it's the first render of the session.
