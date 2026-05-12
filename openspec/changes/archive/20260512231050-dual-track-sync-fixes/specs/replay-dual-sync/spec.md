## ADDED Requirements

### Requirement: Dual-track anchoring in initial replay trigger
The system SHALL immediately anchor both primary (`FSM.ACTIVE_IDX`) and secondary (`FSM.SEC_ACTIVE_IDX`) subtitle indices to their replay start positions when `cmd_replay_sub()` is triggered, before issuing the seek command.

#### Scenario: Replay in Autopause OFF mode anchors both tracks
- **WHEN** user presses `s` to trigger Replay in Autopause OFF mode
- **THEN** `replay_start_idx` is computed for the primary track
- **THEN** `sec_replay_start_idx` is computed for the secondary track
- **THEN** `FSM.ACTIVE_IDX` is immediately set to `replay_start_idx`
- **THEN** `FSM.SEC_ACTIVE_IDX` is immediately set to `sec_replay_start_idx`
- **THEN** the seek command is issued

#### Scenario: Replay in Autopause ON mode anchors both tracks
- **WHEN** user presses `s` to trigger Replay in Autopause ON mode
- **THEN** `replay_start_idx` is computed for the primary track
- **THEN** `sec_replay_start_idx` is computed for the secondary track
- **THEN** `FSM.ACTIVE_IDX` is immediately set to `replay_start_idx`
- **THEN** `FSM.SEC_ACTIVE_IDX` is immediately set to `sec_replay_start_idx`
- **THEN** the seek command is issued

### Requirement: Dual-track anchoring in loop iterations
The system SHALL immediately anchor both primary and secondary subtitle indices to the loop start position at each loop iteration in `tick_loop()`.

#### Scenario: Loop iteration anchors both tracks
- **WHEN** a loop iteration occurs during Replay in Autopause OFF mode
- **THEN** `FSM.ACTIVE_IDX` is immediately set to the index at `FSM.LOOP_START`
- **THEN** `FSM.SEC_ACTIVE_IDX` is immediately set to the index at `FSM.LOOP_START`
- **THEN** the seek command is issued to `FSM.LOOP_START`

### Requirement: Dual-track anchoring in scheduled replay iterations
The system SHALL immediately anchor both primary and secondary subtitle indices to the scheduled replay start position at each scheduled replay iteration in `tick_scheduled_replay()`.

#### Scenario: Scheduled replay iteration anchors both tracks
- **WHEN** a scheduled replay iteration occurs during Replay in Autopause ON mode
- **THEN** `FSM.ACTIVE_IDX` is immediately set to the index at `FSM.SCHEDULED_REPLAY_START`
- **THEN** `FSM.SEC_ACTIVE_IDX` is immediately set to the index at `FSM.SCHEDULED_REPLAY_START`
- **THEN** the seek command is issued to `FSM.SCHEDULED_REPLAY_START`

### Requirement: Synchronization preservation during repeated Replay
The system SHALL maintain dual-track synchronization across multiple consecutive Replay operations.

#### Scenario: Five consecutive Replay presses in Autopause ON mode
- **WHEN** user presses `s` five times consecutively in Autopause ON mode
- **THEN** after each Replay press, `active_sub_index` equals `sec_active_sub_index`
- **THEN** no drift occurs between primary and secondary tracks

#### Scenario: Five consecutive Replay presses in Autopause OFF mode
- **WHEN** user presses `s` five times consecutively in Autopause OFF mode
- **THEN** after each Replay press, `active_sub_index` equals `sec_active_sub_index`
- **THEN** no drift occurs between primary and secondary tracks

### Requirement: Secondary replay start index computation
The system SHALL compute the secondary replay start index (`sec_replay_start_idx`) using the same `get_center_index()` function used for the primary track.

#### Scenario: Secondary replay start index is computed
- **WHEN** `cmd_replay_sub()` is called
- **THEN** `sec_replay_start_idx` is computed by calling `get_center_index(sec_subs, replay_start)`
- **THEN** the computed index is used to anchor `FSM.SEC_ACTIVE_IDX`

#### Scenario: Secondary replay start index handles empty track
- **WHEN** the secondary subtitle track is empty or not available
- **THEN** `sec_replay_start_idx` is set to -1
- **THEN** no anchoring is attempted for the secondary track
