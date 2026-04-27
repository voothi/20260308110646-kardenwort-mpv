## ADDED Requirements

### Requirement: Visual Gap Simulation
The `\vsp` tag must be used to adjust the spacing of the OSD `separator` (`\N` or `\N\N`) so that it matches the `block_gap_mul` setting.

#### Scenario: Negative Block Gap
- **WHEN** `block_gap_mul` is negative
- **THEN** apply a negative `\vsp` to the newline character(s) in the separator to compress the visual gap.
