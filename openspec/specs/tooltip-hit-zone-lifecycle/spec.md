## Purpose
Define lifecycle and guard rules for tooltip hit-zones so interaction metadata remains valid, mode-safe, and synchronized with visible tooltip state.
## Requirements
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

### Requirement: Drum Tooltip Hit-Zone Lifecycle Parity
Tooltip interaction metadata SHALL be lifecycle-managed in Drum Mode with the same isolation guarantees used for Drum Window.

#### Scenario: Drum tooltip clear on lifecycle break
- **WHEN** Drum tooltip visual state is cleared due to mouse-out, mode change, or key toggle-off
- **THEN** Drum tooltip hit-zones SHALL be invalidated in the same lifecycle path.

### Requirement: Drum Tooltip Hit-Test Guard
Hit-testing for Drum tooltip interactions SHALL verify Drum tooltip logical activation before accepting a hit-zone result.

#### Scenario: Guarded Drum tooltip hit-test
- **WHEN** a Drum tooltip hit-test is requested while Drum tooltip logical state is inactive
- **THEN** the system SHALL return no tooltip hit result even if stale metadata exists in memory.

