## ADDED Requirements

### Requirement: Mode-B Selection Source Consistency
In `Copy Subtitle Mode: B`, the export engine SHALL use the secondary subtitle track as the source for all supported selection types.

#### Scenario: Point export in mode B
- **WHEN** a single-point selection is exported while `COPY_MODE` is `B`
- **THEN** exported text MUST be resolved from the secondary subtitle track at the same subtitle index

#### Scenario: Range export in mode B
- **WHEN** a contiguous range selection is exported while `COPY_MODE` is `B`
- **THEN** each selected token MUST be resolved from secondary-track subtitle text for the corresponding lines

#### Scenario: Set export in mode B
- **WHEN** a non-contiguous set selection is exported while `COPY_MODE` is `B`
- **THEN** selected members and gap interpolation MUST be computed from secondary-track subtitle text
