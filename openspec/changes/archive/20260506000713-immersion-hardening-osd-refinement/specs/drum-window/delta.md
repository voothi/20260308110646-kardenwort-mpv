## ADDED Requirements

### Requirement: Non-Cyclic Esc Handler
The `Esc` key handler MUST prioritize clearing selections and pointers over closing the Drum Window state.

#### Scenario: Clearing a Multi-Word Selection
- **WHEN** a yellow range selection is active and `Esc` is pressed
- **THEN** the selection MUST be cleared, but the Drum Window MUST remain active.

### Requirement: Staged Reset Hierarchy
The `Esc` key MUST follow a strict staged hierarchy for clearing state:
1. Stage 1: Clear Pending Set (Pink).
2. Stage 2: Clear Range Selection (Yellow).
3. Stage 3: Full Pointer Reset & Cursor Synchronization.

#### Scenario: Pressing Esc with no selections
- **WHEN** no selections or pointers are active
- **THEN** pressing `Esc` MUST perform no further action (the window remains open).

### Requirement: Immersion Input Blocking
Subtitle positioning controls MUST be intercepted and suppressed when the Drum Window or Drum Mode is active to prevent accidental visual disruption.

#### Scenario: Pressing 'r' during Drum Mode
- **WHEN** Drum Mode is ON
- **THEN** the 'r' key MUST be blocked and provide no OSD feedback.
