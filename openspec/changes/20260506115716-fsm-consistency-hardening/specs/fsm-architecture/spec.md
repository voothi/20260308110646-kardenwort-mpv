# Delta Specification: FSM Consistency Hardening

## ADDED Requirements

### Requirement: Search Exit Interactivity Restoration
When search mode is deactivated, the system must restore full interactivity (both mouse and keyboard) for the Drum Window if it is in DOCKED mode.

#### Scenario: Restoring Bindings after Search
- **WHEN** the user closes the Search HUD (ESC/Enter) while the Drum Window is DOCKED
- **THEN** both mouse click handlers and keyboard navigation bindings (Arrows, Enter) must be reactivated.

### Requirement: Early Padding Handover (Phrases Mode)
In Phrases mode, the system must prioritize the upcoming subtitle's padded start over the current subtitle's padded end to allow Jerk-Back logic to fire correctly.

#### Scenario: Entering Overlap Gap
- **WHEN** the playhead enters a gap where the next subtitle's padded start has begun
- **THEN** the active index must switch to the next subtitle immediately, even if the current subtitle's padded end has not been reached.

### Requirement: Sticky X Anchor Synchronization
The horizontal "Sticky X" anchor must be updated immediately upon any manual focus change to ensure consistent vertical navigation.

#### Scenario: Manual Horizontal Navigation
- **WHEN** the user moves the cursor horizontally (Left/Right) or clicks a word
- **THEN** the `DW_CURSOR_X` anchor must be recalculated for the new focus point to prevent snapping back to the previous X coordinate during the next vertical move.
