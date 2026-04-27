## ADDED Requirements

### Requirement: Visual Gap Simulation
The `\vsp` tag must be used to adjust the spacing of the OSD `separator` in double-gap mode so that it matches the `block_gap_mul` setting.

#### Scenario: Negative Block Gap
- **WHEN** `block_gap_mul` is negative
- **THEN** apply a negative `\vsp` (halved) to the `\N\N` separator to compress the visual gap.
- **AND** ensure single `\N` separators (single gap) are not affected by `block_gap_mul`.

