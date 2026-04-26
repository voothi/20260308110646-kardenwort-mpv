## MODIFIED Requirements

### Requirement: Periodic Database Sync
The application SHALL periodically re-synchronize the in-memory highlight dictionary with the state of the physical TSV file. To minimize CPU utilization, the system MUST implement a change-detection fingerprinting mechanism.

#### Scenario: Real-time update from file edit
- **WHEN** the user or an external process modifies the TSV database file
- **THEN** within a configurable interval (5s), the player system detects the modified fingerprint.
- **AND** it reloads the file atomically (using `pcall` for safety) and refreshes all active subtitle viewports (Drum, Timeline, and standard OSD) to reflect the new state.

#### Scenario: Optimized idempotent sync
- **WHEN** the periodic sync trigger occurs
- **AND** the TSV file fingerprint matches the current in-memory state
- **THEN** the system SHALL skip the parse operation to conserve CPU resources.
