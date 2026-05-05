# Delta Spec: fsm-architecture

## Modified Requirements

### Requirement: Immersion Mode Transition FSM
The system SHALL ensure that transitions between Immersion Modes (`MOVIE`, `PHRASE`) do not trigger unintended seeking or playback behavior.
- **State Alignment**: When toggling to `PHRASE` mode, the system SHALL immediately synchronize `FSM.ACTIVE_IDX` with the current subtitle index based on `time-pos`.
- **Efficacy**: This synchronization MUST occur before the next tick of the master loop to prevent "Jerk Back" logic from detecting a phantom subtitle boundary.

#### Scenario: Syncing state on Phrase mode toggle
- **WHEN** the user toggles from `MOVIE` to `PHRASE` mode
- **THEN** the system SHALL calculate the current `active_idx` and store it in `FSM.ACTIVE_IDX` immediately.
- **AND** the subsequent tick loop SHALL NOT trigger a "Jerk Back" seek if the playback position is at a subtitle boundary.
