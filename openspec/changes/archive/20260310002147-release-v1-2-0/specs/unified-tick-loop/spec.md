## ADDED Requirements

### Requirement: Master Processing Tick
The system SHALL coordinate all runtime calculations and state tracking using a singular master periodic timer.

#### Scenario: Synchronized processing
- **WHEN** the system is running
- **THEN** it SHALL execute a master tick loop every 0.05 seconds to update coordinates and track subtitle timing.

### Requirement: Feature Boundary Enforcement
The system SHALL use the master tick loop to enforce feature boundaries based on the current `MEDIA_STATE`.

#### Scenario: Auto-disabling Drum Mode
- **WHEN** the `MEDIA_STATE` indicates a complex or unsupported subtitle track
- **THEN** the master tick loop SHALL automatically bypass Drum Mode rendering.
