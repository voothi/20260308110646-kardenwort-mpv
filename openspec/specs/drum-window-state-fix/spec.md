# Spec: Drum Window State Fix

## Context
Inconsistent state field names can lead to silent failures in selection logic.

## Requirements
- Update `cmd_dw_word_move` to use `FSM.DW_ANCHOR_LINE` instead of the legacy `FSM.ANCHOR_LINE`.
- Audit all Drum Window functions to ensure they consistently use the `DW_` prefix for Drum-specific state fields.

### Requirement: Cursor Synchronization
The system MUST synchronize `FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, and `FSM.DW_VIEW_CENTER` with the active playback index (`active_idx`) whenever `FSM.DW_FOLLOW_PLAYER` is true, ensuring the cursor correctly tracks the currently playing subtitle.

#### Scenario: Continuous Playback in Drum Mode
- **WHEN** the player advances to the next subtitle during continuous playback in Drum Mode (Drum Window closed) and `FSM.DW_FOLLOW_PLAYER` is true
- **THEN** `FSM.DW_CURSOR_LINE` is updated to match the new `active_idx`, and `FSM.DW_CURSOR_WORD` is reset to `-1`

## Verification
- Use the Drum Window and perform multi-word selection.
- Verify that the selection anchor persists correctly across movements.
