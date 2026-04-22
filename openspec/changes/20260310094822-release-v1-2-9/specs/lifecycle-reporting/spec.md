## ADDED Requirements

### Requirement: Permanent Development Snapshots
The system SHALL support the generation of permanent markdown reports that capture the development state and effort of a specific release.

#### Scenario: Archiving a report
- **WHEN** a release milestone is reached
- **THEN** a ZID-prefixed report file SHALL be created in the `docs/reports/` directory containing the latest analytics data.

### Requirement: Integrated README Analytics
The project `README.md` SHALL contain a dedicated section summarizing the current development intensity and historical metrics of the suite.

#### Scenario: Viewing README
- **WHEN** a user views the `README.md`
- **THEN** they SHALL find a "Development Analytics" section with up-to-date project metrics.
