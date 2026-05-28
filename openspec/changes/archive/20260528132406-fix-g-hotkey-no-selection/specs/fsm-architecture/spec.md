## ADDED Requirements

### Requirement: Universal Cursor Synchronization during Free Playback
When `FSM.DW_FOLLOW_PLAYER` is active and there is no range selection or word pointer active (`FSM.DW_ANCHOR_LINE == -1` and `FSM.DW_CURSOR_WORD == -1`), the system MUST continuously synchronize `FSM.DW_CURSOR_LINE` to the live `active_idx` on every tick of the master loop.
- This synchronization SHALL occur regardless of whether `FSM.DW_VIEW_CENTER` has changed.
- This synchronization SHALL occur in both Book Mode and non-Book Mode to prevent cursor drift during playback.

#### Scenario: Subtitles playing in follow mode
- **GIVEN** `FSM.DW_FOLLOW_PLAYER` is true and no selection is active (`FSM.DW_ANCHOR_LINE == -1` and `FSM.DW_CURSOR_WORD == -1`)
- **WHEN** the master tick loop executes and resolves the new `active_idx`
- **THEN** the system SHALL set `FSM.DW_CURSOR_LINE` to `active_idx`
- **AND** set `FSM.DW_CURSOR_X` to `nil` to clear transient selection coordinates.
