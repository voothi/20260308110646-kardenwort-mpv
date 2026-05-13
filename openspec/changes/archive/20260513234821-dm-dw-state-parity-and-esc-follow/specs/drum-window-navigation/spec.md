## MODIFIED Requirements

### Requirement: Startup and Recovery Logic
The system SHALL ensure that navigation is available immediately upon script initialization and after staged clear transitions.

#### Scenario: Deterministic Null-Selection Entry Source
- **WHEN** selection is cleared to null state (`DW_CURSOR_WORD = -1`)
- **AND** user performs first navigation action
- **THEN** the source logical line SHALL resolve in order:
1. valid standing cursor line (`DW_CURSOR_LINE`),
2. otherwise active playback line (`DW_ACTIVE_LINE`).
- **AND** this resolution SHALL be identical in Drum Window (W) and Drum Mode (C).

#### Scenario: First LEFT/RIGHT After Null Selection
- **WHEN** `DW_CURSOR_WORD = -1` and user presses RIGHT
- **THEN** pointer SHALL activate on first navigable token of resolved source line.
- **AND** pressing LEFT SHALL activate on last navigable token of resolved source line.

#### Scenario: Null Selection After Manual Seek/Scroll
- **WHEN** pointer is cleared (`DW_CURSOR_WORD = -1`)
- **AND** user performs manual seek (`a`/`d`) or explicit viewport scroll
- **THEN** standing logical source line for next pointer activation SHALL synchronize to latest manual context:
1. manual seek target line,
2. otherwise manual viewport center line,
3. otherwise active playback line.
- **AND** next arrow activation SHALL use this synchronized line instead of stale pre-seek/pre-scroll line.
