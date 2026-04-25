## MODIFIED Requirements

### Requirement: Independent Pointer and Selection States
The Drum Window SHALL maintain separate states for the active video subtitle (white) and the manual navigation cursor (yellow) to allow for decoupled reading and seeking.

#### Scenario: Manual Seek in Book Mode
- **WHEN** the user presses `a` or `d` in Book Mode
- **THEN** the video SHALL seek AND the white active highlight SHALL move AND the yellow cursor highlight SHALL NOT be updated (maintaining its current position).

#### Scenario: Selection Dismissal on Manual Seek
- **WHEN** the user starts manual seeking via `a`/`d` in Book Mode OFF
- **THEN** any active yellow word-focus (`DW_CURSOR_WORD`) SHALL be dismissed (`-1`).

#### Scenario: Automatic Selection Cleanup (Regular Mode)
- **WHEN** the system is in Book Mode OFF and the playback moves to a new subtitle
- **THEN** the yellow line highlight SHALL follow the player AND the yellow word-focus SHALL be reset to `-1`.
