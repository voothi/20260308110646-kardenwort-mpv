# Spec Delta: Tooltip Stability

## New Requirements

### Requirement: Tooltip OSD Update Suppression
The system SHALL only call OSD update routines for the tooltip when the generated ASS content has changed compared to the current OSD state.
- **Rationale**: Prevent cyclical flickering on periodic tick events.

### Requirement: Deterministic Tooltip Positioning
The system SHALL round all calculated OSD Y-coordinates for tooltips to the nearest integer pixel.
- **Rationale**: Ensure cache stability and prevent sub-pixel jitter in the OSD display.

### Requirement: DW Hover Routing Stability at Borders
When Drum Window is active, DW tooltip hover resolution SHALL use DW primary hit-testing as the routing source.
- **Rationale**: Prevent border flicker caused by mixed tooltip/primary hit-zone resolution.

#### Scenario: Cursor moves along DW border in HOVER mode
- **WHEN** `FSM.DRUM_WINDOW ~= "OFF"` and tooltip mode is `HOVER`
- **AND** the pointer moves along subtitle border regions
- **THEN** tooltip targeting SHALL remain stable without oscillating visibility.
