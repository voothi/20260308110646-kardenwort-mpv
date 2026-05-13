## MODIFIED Requirements

### Requirement: Staged Reset Hierarchy
The `Esc` key MUST follow a strict staged hierarchy for clearing state:
1. Stage 1: Clear Pending Set (Pink).
2. Stage 2: Clear Range Selection (Yellow).
3. Stage 3: Full Pointer Reset & Cursor Synchronization.

#### Scenario: Stage 3 Restores Follow Leading
- **WHEN** Stage 3 is reached (final yellow pointer clear)
- **THEN** the system SHALL restore normal follow-leading mode (`DW_FOLLOW_PLAYER = true`)
- **AND** manual seek transit markers used for repeated `a`/`d` stepping SHALL be cleared
- **AND** this restore SHALL apply in both Drum Window (W) and Drum Mode (C).

#### Scenario: Stage 3 Uses Current Playback Anchor
- **WHEN** Stage 3 executes near subtitle boundaries
- **THEN** cursor synchronization SHALL anchor to the current active playback subtitle
- **AND** the next transition SHALL continue from this updated anchor rather than stale pre-boundary line context.

### Requirement: Cross-Mode Cursor Synchronization
The sequential Escape mechanism SHALL be applied uniformly in both Drum Mode (Mode C) and Drum Window (Mode W).

#### Scenario: Escape synchronization in Mode C
- **WHEN** Drum Mode (Mode C) is ON and Drum Window (Mode W) is OFF
- **AND** a selection (Pink, Yellow Range, or Pointer) exists and user presses `Esc`
- **THEN** the system SHALL evaluate and clear states in sequential order
- **AND** final pointer clear SHALL synchronize `DW_CURSOR_LINE` with current playback line
- **AND** follow-leading SHALL be re-enabled immediately after this final clear.
