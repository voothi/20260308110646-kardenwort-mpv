## MODIFIED Requirements

### Requirement: Autopause Coordination (AUTOPAUSE / SPACEBAR)
The FSM SHALL coordinate autopause with a deterministic transit-inhibit lifecycle for manual navigation, including set, guarded execution, and clear phases.

#### Scenario: Transit inhibit lifecycle for cross-card navigation
- **WHEN** manual navigation or replay command determines a cross-card transition
- **THEN** FSM MUST set transit inhibition state before boundary evaluation
- **AND** master playback loop MUST honor inhibition gates for autopause and PHRASE jerk-back branches
- **AND** inhibition MUST clear only on deterministic completion criteria.

#### Scenario: Stale inhibit hygiene on unrelated manual jumps
- **WHEN** manual navigation actions occur outside the original rewind transit path
- **THEN** FSM MUST clear stale transit inhibition state before applying new navigation state
- **AND** subsequent boundary decisions MUST use the current navigation context only.
