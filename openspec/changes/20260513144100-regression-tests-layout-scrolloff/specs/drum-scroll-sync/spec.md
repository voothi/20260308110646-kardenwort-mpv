## ADDED Requirements

### Requirement: Scrolloff-Aware Viewport Clamping
The drum viewport logic SHALL respect a configurable scrolloff margin while ensuring the margin never results in negative values that could destabilize the vertical selection pointer.

#### Scenario: Viewport margin clamping to zero
- **WHEN** `drum_scrolloff` or `dw_scrolloff` results in a calculated margin less than zero
- **THEN** the system SHALL clamp the margin to exactly `0`
- **AND** the yellow viewport pointer SHALL remain correctly aligned with the target line.
