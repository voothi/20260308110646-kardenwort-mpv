## MODIFIED Requirements

### Requirement: Navigation-Aware Boundary Suppression
The immersion engine MUST suppress autopause boundary triggers and PHRASE overlap jerk-back only during intentional cross-card subtitle navigation transit.

#### Scenario: Cross-card rewind transit in Autopause ON + PHRASE
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** the user invokes subtitle navigation (`Shift+a`, `Shift+d`, or replay `s`) that transitions playback to a different subtitle card
- **THEN** the engine MUST activate transit inhibition
- **AND** while inhibition is active it MUST suppress both boundary-based autopause stops and PHRASE jerk-back overlap seeks.

#### Scenario: Inside-card rewind retains normal phrase-end pause
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** the user invokes rewind/navigation that remains within the same subtitle card
- **THEN** cross-card transit inhibition MUST NOT be activated
- **AND** normal PHRASE end-of-card autopause behavior MUST remain active.

#### Scenario: Transit completion restores standard PHRASE behavior
- **WHEN** a cross-card transit inhibition is active
- **AND** transit completion criteria are met by playback position/state
- **THEN** inhibition MUST clear deterministically
- **AND** subsequent boundary behavior MUST follow normal PHRASE rules.
