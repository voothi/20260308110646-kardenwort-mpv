## MODIFIED Requirements

### Requirement: Manual Navigation Suppression
The autopause mechanism MUST suppress pause triggers only for cross-card manual navigation transit and MUST preserve normal end-of-card pause behavior for inside-card movement.

#### Scenario: Cross-card rewind during Autopause ON
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** the user invokes `Shift+a` or `Shift+d` and the resulting transit crosses subtitle-card boundaries
- **THEN** `tick_autopause` MUST suppress boundary pauses during active transit inhibit
- **AND** suppression MUST end when transit completion is reached.

#### Scenario: Inside-card rewind during Autopause ON
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** user rewind/navigation remains within the active subtitle card
- **THEN** `tick_autopause` MUST continue normal phrase-end pause checks
- **AND** it MUST NOT treat this case as cross-card suppression transit.
