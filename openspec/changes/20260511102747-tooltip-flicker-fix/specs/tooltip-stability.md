# Spec Delta: Tooltip Stability

## New Requirements

### Requirement: Tooltip OSD Update Suppression
The system SHALL only call OSD update routines for the tooltip when the generated ASS content has changed compared to the current OSD state.
- **Rationale**: Prevent cyclical flickering on periodic tick events.

### Requirement: Deterministic Tooltip Positioning
The system SHALL round all calculated OSD Y-coordinates for tooltips to the nearest integer pixel.
- **Rationale**: Ensure cache stability and prevent sub-pixel jitter in the OSD display.
