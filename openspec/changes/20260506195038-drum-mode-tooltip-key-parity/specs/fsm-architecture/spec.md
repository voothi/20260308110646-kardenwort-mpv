## ADDED Requirements

### Requirement: Drum Tooltip Overlay Ownership Gate
The FSM SHALL permit tooltip overlay rendering in Drum Mode only when Drum Mode owns the primary OSD surface and Drum Window is inactive.

#### Scenario: Drum-owned tooltip render eligibility
- **WHEN** `FSM.DRUM == "ON"` and `FSM.DRUM_WINDOW == "OFF"`
- **THEN** Drum Mode tooltip rendering SHALL be eligible
- **AND** eligibility SHALL be revoked immediately when either condition becomes false.

### Requirement: Transition-Edge Tooltip Invalidation
The FSM SHALL clear tooltip visual state and invalidate tooltip hit-zones on every transition edge that changes tooltip ownership between Drum Mode and Drum Window.

#### Scenario: Switching from Drum Mode to Drum Window
- **WHEN** `FSM.DRUM_WINDOW` transitions from `"OFF"` to `"DOCKED"` while Drum tooltip state is active
- **THEN** Drum tooltip overlay buffers and Drum tooltip hit-zones SHALL be cleared before DW tooltip ownership is applied.
