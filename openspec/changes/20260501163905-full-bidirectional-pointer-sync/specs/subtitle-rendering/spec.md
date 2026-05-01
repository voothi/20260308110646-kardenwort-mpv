# Delta: Subtitle Rendering (Universal Pointer)

## ADDED Requirements

### Requirement: Universal Pointer Persistence
The system SHALL maintain the visibility and logical anchoring of the word pointer (Yellow Highlight) across all subtitle rendering modes, including windowless (SRT) playback.

#### Scenario: Pointer visibility in Regular SRT mode
- **WHEN** the Drum Window (Mode W) is OFF and Drum Mode (Mode C) is OFF (Regular SRT mode).
- **IF** `FSM.DW_CURSOR_WORD` is not -1.
- **THEN** the active primary subtitle SHALL render with a yellow highlight on the specified word.
