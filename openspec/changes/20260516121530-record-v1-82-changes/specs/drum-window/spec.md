## ADDED Requirements

### Requirement: Atomic UI Toggling
The Drum Window toggle SHALL be atomic and resilient to Lua errors during initialization.

#### Scenario: Recovery from Initialization Error
- **WHEN** an error occurs inside `cmd_toggle_drum_window` (e.g., TSV load failure)
- **THEN** the system SHALL catch the error via `xpcall`
- **AND** the FSM state (`FSM.DRUM_WINDOW`) SHALL be rolled back to its previous value (usually `OFF`)
- **AND** a diagnostic error message SHALL be displayed to the user.

### Requirement: Stable Line Resolution
During null-activation events (e.g., clicking on whitespace or seeking to an empty gap), the Drum Window SHALL prioritize stable, player-synchronized line indices.

#### Scenario: Null Activation Preference
- **WHEN** `dw_resolve_null_activation_line` is invoked
- **THEN** it SHALL prefer `FSM.DW_ACTIVE_LINE` or `FSM.ACTIVE_IDX` (direct player sync) over lookahead-derived context.
- **AND** lookahead context SHALL only be used as a secondary fallback.
