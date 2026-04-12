## ADDED Requirements

### Requirement: Mouse Motion Tracking
The system SHALL continuously track and evaluate the mouse position during Drum Window Mode.

#### Scenario: Pointer deviates from pinned line
- **WHEN** the user is dragging or simply moving the mouse without dragging
- **AND** the tooltip window layer relies on hover dynamics
- **THEN** the system SHALL actively supply `hit_test` events to the tooltip manager

### Requirement: RMB Interaction
The system SHALL bind `MBTN_RIGHT` dynamically when Drum Window mode activates.

#### Scenario: Tooltip Click Trigger
- **WHEN** in Drum Window Mode
- **THEN** `MBTN_RIGHT` SHALL dispatch drawing instructions to pin the tooltip 
- **AND** this explicit binding SHALL automatically deactivate when Window mode drops

### Requirement: Hover Mode Toggle
The system SHALL support a configurable hotkey to toggle Phase 2 "Hover Mode".

#### Scenario: User toggles Hover Mode using configured key
- **WHEN** the user is in Drum Window Mode
- **AND** the user presses the `dw_tooltip_hover_key` (e.g. `n`) mapped in configuration
- **THEN** the system SHALL swap `FSM.DW_TOOLTIP_MODE` between "CLICK" and "HOVER"
- **AND** while in "HOVER" mode, mouse motion hit-tests automatically pin the tooltip without requiring `MBTN_RIGHT`
