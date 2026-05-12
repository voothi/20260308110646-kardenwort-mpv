## ADDED Requirements

### Requirement: Immediate dual-track anchoring during time seeks
The system SHALL immediately anchor both primary (`FSM.ACTIVE_IDX`) and secondary (`FSM.SEC_ACTIVE_IDX`) subtitle indices to their target positions when performing Shift+A/D time-based seeks, before issuing the seek command.

#### Scenario: Shift+D forward seek anchors both tracks
- **WHEN** user presses Shift+D to seek forward by 2 seconds
- **THEN** `FSM.ACTIVE_IDX` is immediately set to the target primary subtitle index
- **THEN** `FSM.SEC_ACTIVE_IDX` is immediately set to the target secondary subtitle index
- **THEN** both tracks display synchronized subtitles without visual lag

#### Scenario: Shift+A backward seek anchors both tracks
- **WHEN** user presses Shift+A to seek backward by 2 seconds
- **THEN** `FSM.ACTIVE_IDX` is immediately set to the target primary subtitle index
- **THEN** `FSM.SEC_ACTIVE_IDX` is immediately set to the target secondary subtitle index
- **THEN** both tracks display synchronized subtitles without visual lag

#### Scenario: Secondary track anchoring with non-aligned timings
- **WHEN** primary and secondary subtitle timings are not perfectly aligned
- **WHEN** user performs a Shift+A/D time seek
- **THEN** both tracks are immediately anchored to their respective target positions
- **THEN** the upper secondary track does not visually lag behind the lower primary track

### Requirement: Secondary target index computation
The system SHALL compute the secondary target index (`sec_target_idx`) during time seek operations using the same `get_center_index()` function used for the primary track.

#### Scenario: Secondary target index is computed
- **WHEN** `cmd_seek_time()` is called with a direction parameter
- **THEN** `sec_target_idx` is computed by calling `get_center_index(sec_subs, target_pos)`
- **THEN** the computed index is used to anchor `FSM.SEC_ACTIVE_IDX`

#### Scenario: Secondary target index handles empty track
- **WHEN** the secondary subtitle track is empty or not available
- **THEN** `sec_target_idx` is set to -1
- **THEN** no anchoring is attempted for the secondary track
