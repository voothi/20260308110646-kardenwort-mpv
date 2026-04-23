## ADDED Requirements

### Requirement: Tracking RFC Migration Progress
The system SHALL maintain a comprehensive checklist of all RFC files in `.\docs\rfcs` to track their migration status to `.\openspec\changes\`.

#### Scenario: Update checklist after migration
- **WHEN** an RFC file is successfully proposed as a new change in `.\openspec\changes\`
- **THEN** the corresponding entry in the migration checklist SHALL be marked as complete.

### Requirement: Granular Migration Process
The migration SHALL proceed one file at a time, requiring a separate `/opsx-propose` command for each RFC.

#### Scenario: Proposing a single RFC
- **WHEN** the user initiates a migration for a specific RFC file
- **THEN** a new change directory SHALL be created with the naming convention `<ZID>-<name>`.
