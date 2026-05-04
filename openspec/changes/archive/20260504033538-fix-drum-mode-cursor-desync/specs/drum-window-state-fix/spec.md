## MODIFIED Requirements

### Requirement: Cursor Synchronization
The system MUST synchronize `FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, and `FSM.DW_VIEW_CENTER` with the active playback index (`active_idx`) whenever `FSM.DW_FOLLOW_PLAYER` is true, ensuring the cursor correctly tracks the currently playing subtitle.

#### Scenario: Continuous Playback in Drum Mode
- **WHEN** the player advances to the next subtitle during continuous playback in Drum Mode (Drum Window closed) and `FSM.DW_FOLLOW_PLAYER` is true
- **THEN** `FSM.DW_CURSOR_LINE` is updated to match the new `active_idx`, and `FSM.DW_CURSOR_WORD` is reset to `-1`
