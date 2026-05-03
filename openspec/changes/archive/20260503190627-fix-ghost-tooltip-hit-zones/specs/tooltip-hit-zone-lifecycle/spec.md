## ADDED Requirements

### Requirement: Tooltip Interaction Isolation
The system SHALL ensure that tooltip interaction metadata (hit-zones) only exists and is active when the tooltip is visually displayed.

#### Scenario: Dragging Suppression
- **WHEN** the user starts a mouse drag (text selection) in the Drum Window
- **THEN** the tooltip OSD MUST be cleared **AND** the tooltip hit-zones MUST be invalidated immediately to prevent interaction drift.

#### Scenario: Mouse-Out Invalidation
- **WHEN** the mouse leaves the tooltip focus area (and RMB is not held)
- **THEN** the tooltip OSD MUST be cleared **AND** the tooltip hit-zones MUST be invalidated.

#### Scenario: Hit-Test Guarding
- **WHEN** a hit-test is performed on the tooltip layer
- **THEN** the system MUST verify that the tooltip is logically active (`DW_TOOLTIP_LINE ~= -1`) before returning any results, regardless of whether hit-zone metadata exists in memory.
