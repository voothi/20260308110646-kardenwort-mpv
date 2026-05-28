## ADDED Requirements

### Requirement: Selection-Free Playback Export Fallback
When an export action is initiated and there is no active selection (meaning no yellow selection range, yellow single-word pointer, or pink pending set is present), the system MUST dynamically resolve the target subtitle line based on the exact live playback `time-pos` at the moment of the export trigger.
- If live `time-pos` is available, the system SHALL resolve the index using `get_center_index`.
- If live `time-pos` is unavailable, the system SHALL fallback to `FSM.DW_ACTIVE_LINE`.
- The system SHALL then export that resolved subtitle line in its entirety.

#### Scenario: Pressing g hotkey during free listening
- **GIVEN** the player is in free listening mode with no active selection or pointer highlight (`FSM.DW_ANCHOR_LINE == -1` and `FSM.DW_CURSOR_WORD == -1`)
- **WHEN** the user triggers the `g` hotkey
- **THEN** the system SHALL fetch the current player `time-pos`
- **AND** resolve the exact active subtitle line at that timestamp
- **AND** export that subtitle line in its entirety to Anki.
