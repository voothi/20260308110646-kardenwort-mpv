## MODIFIED Requirements

### Requirement: Deterministic Null-Selection Entry Source
- **WHEN** the selection is cleared to null state (e.g., final `Esc` stage with `DW_CURSOR_WORD = -1`)
- **AND** the user performs the first navigation action
- **THEN** the "current logical line" SHALL resolve in this order:
1. Current `EVENT_SNAPSHOT` active line (if playback is active).
2. Existing standing cursor line (`DW_CURSOR_LINE`) when valid.
3. Otherwise the active playback subtitle line (`DW_ACTIVE_LINE`).
- **AND** this source resolution SHALL be identical in Drum Window (W) and Drum Mode (C).

#### Scenario: Entry from Null Selection (Post-Esc)
- **WHEN** the Drum Window has no active selection (`DW_CURSOR_WORD = -1`).
- **AND** the user presses DOWN.
- **THEN** the yellow pointer SHALL activate on the FIRST visual line of the current logical line.
- **AND** if the user presses UP while listening, it SHALL activate on the middle word of the current logical line.
- **AND** if the user presses UP while paused, it SHALL activate on the LAST visual line of the current logical line.

#### Scenario: Deterministic Null-Selection Entry Source
- **WHEN** the selection is cleared to null state (e.g., final `Esc` stage with `DW_CURSOR_WORD = -1`)
- **AND** the user performs the first navigation action
- **THEN** the "current logical line" SHALL resolve in this order:
1. Current `EVENT_SNAPSHOT` active line (if playback is active).
2. Existing standing cursor line (`DW_CURSOR_LINE`) when valid.
3. Otherwise the active playback subtitle line (`DW_ACTIVE_LINE`).
- **AND** this source resolution SHALL be identical in Drum Window (W) and Drum Mode (C).
