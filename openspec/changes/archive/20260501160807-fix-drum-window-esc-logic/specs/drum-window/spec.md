# Delta: Drum Window (Sequential Escape)

## MODIFIED Requirements

### Requirement: Cross-Mode Cursor Synchronization
The sequential Escape mechanism SHALL be applied uniformly in both Drum Mode (Mode C) and Drum Window (Mode W).

#### Scenario: Escape synchronization in Mode C (Refined)
- **WHEN** Drum Mode (Mode C) is ON and the Drum Window (Mode W) is OFF
- **WHEN** A selection (Pink, Yellow Range, or Pointer) exists and the user presses `Esc`
- **THEN** The system SHALL evaluate and clear states in sequential order:
  1. Pink Set
  2. Yellow Range (to Pointer)
  3. Yellow Pointer
- **AND** When the final Yellow Pointer is cleared, `FSM.DW_CURSOR_LINE` MUST be synchronized with the currently active playback line index.
