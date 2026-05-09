# Delta Specification: Immersion Engine

## ADDED Requirements

### Requirement: Navigation-Aware Boundary Suppression
The immersion engine MUST suppress all autopause triggers and boundary-enforced stops during intentional subtitle navigation.

#### Scenario: Subtitle Rewind (Shift+a) in Phrases Mode
- **WHEN** `FSM.AUTOPAUSE == "ON"`.
- **AND** The user performs a subtitle jump (`Shift+a` or `Shift+d`).
- **THEN** All boundary-based pause triggers MUST be suspended for the duration of the jump and a subsequent "settle" period.
- **AND** The system MUST NOT treat the entry into the target subtitle's padded boundary as a "Natural Progression" pause event.

#### Scenario: Transient Movie Mode Guard
- **WHEN** A manual subtitle jump is initiated.
- **THEN** The engine MUST internally treat the transition as a `MOVIE` mode handover (gapless) to prevent the "jerking" effect of padded boundaries.
- **AND** Normal `PHRASE` mode behavior MUST be restored once the playhead reaches the target subtitle's effective start.
