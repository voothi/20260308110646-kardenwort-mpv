## ADDED Requirements

### Requirement: Stationary Yellow Pointer in Book Mode
The Drum Window SHALL ensure that the yellow pointer (word focus) remains stationary in its original logical position during non-navigational state changes when Book Mode is active.

#### Scenario: Playback Progression in Book Mode
- **WHEN** Book Mode is ON and the player moves to a new active subtitle line
- **THEN** the yellow pointer SHALL remain on its original subtitle line AND original word index.

#### Scenario: Seek Operation in Book Mode
- **WHEN** Book Mode is ON and the user seeks via `a` or `d`
- **THEN** the yellow pointer SHALL NOT be updated or cleared AND SHALL remain on its current line and word.

### Requirement: Explicit Pointer Dismissal
The system SHALL provide a dedicated mechanism to clear the independent pointer state in Book Mode to allow returning to player-following focus.

#### Scenario: Dismissing Pointer with Esc
- **WHEN** Book Mode is ON and a yellow pointer is active
- **THEN** pressing `Esc` SHALL set `DW_CURSOR_LINE` to `-1` AND `DW_CURSOR_WORD` to `-1`.
