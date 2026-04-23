## ADDED Requirements

### Requirement: Synchronous Media Engine Update
The system SHALL use absolute and exact seek commands for all subtitle-based navigation jumps to ensure track synchronization.

#### Scenario: Jumping to search result
- **WHEN** the user selects a search result
- **THEN** the system SHALL execute `seek <time> absolute+exact` to force a synchronous update of both primary and secondary tracks.
