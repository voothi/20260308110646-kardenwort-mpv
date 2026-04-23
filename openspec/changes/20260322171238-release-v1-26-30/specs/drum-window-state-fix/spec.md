# Spec: Drum Window State Fix

## Context
Inconsistent state field names can lead to silent failures in selection logic.

## Requirements
- Update `cmd_dw_word_move` to use `FSM.DW_ANCHOR_LINE` instead of the legacy `FSM.ANCHOR_LINE`.
- Audit all Drum Window functions to ensure they consistently use the `DW_` prefix for Drum-specific state fields.

## Verification
- Use the Drum Window and perform multi-word selection.
- Verify that the selection anchor persists correctly across movements.
