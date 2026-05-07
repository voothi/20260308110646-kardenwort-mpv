## MODIFIED Requirements

### Requirement: Secondary Position Bounds via Configuration
Secondary subtitle positioning transitions SHALL respect configured FSM bounds rather than hardcoded constants. `FSM.native_sec_sub_pos` SHALL be kept synchronized with the actual mpv `secondary-sub-pos` property at all times, including after delta-based position adjustments and after toggle operations, so that direction-aware toggle operations always operate from correct state.

#### Scenario: Cycling secondary subtitle position
- **WHEN** `cycle-secondary-pos` is triggered
- **THEN** the system SHALL toggle `secondary-sub-pos` between `Options.sec_pos_top` and `Options.sec_pos_bottom`
- **AND** overlap avoidance SHALL be achieved by validated configuration defaults (for example `sec_pos_bottom = 90` relative to primary `95`), not by implicit runtime clamping.

#### Scenario: Delta position adjustment syncs FSM state
- **WHEN** `cmd_adjust_sec_sub_pos` is called with a delta value
- **THEN** the system SHALL compute the new position, apply it to the mpv property, and write the same value back to `FSM.native_sec_sub_pos`
- **AND** a subsequent call to `cmd_cycle_sec_pos` SHALL use the synchronized `FSM.native_sec_sub_pos` to determine correct toggle direction.

#### Scenario: Toggle cycle syncs FSM state in all branches
- **WHEN** `cmd_cycle_sec_pos` is triggered regardless of `FSM.DRUM` state
- **THEN** the system SHALL write the computed new position to both the mpv `secondary-sub-pos` property and `FSM.native_sec_sub_pos`
- **AND** a subsequent call to `cmd_cycle_sec_pos` in Drum Mode SHALL read the synchronized `FSM.native_sec_sub_pos` and toggle in the correct direction.
