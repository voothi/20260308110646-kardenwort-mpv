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

#### Scenario: Space hold in Autopause ON + PHRASE uses temporary MOVIE flow
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** immersion mode is `PHRASE`
- **AND** the user holds `Space`
- **THEN** boundary progression MUST use MOVIE-like seamless handover while the key is held
- **AND** when `Space` is released (including implicit release caused by multi-key hardware/mpv behavior), normal PHRASE end-of-card autopause MUST resume at the next valid boundary.
