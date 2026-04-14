## ADDED Requirements

### Requirement: Initialization Resilience against Missing Data
The Drum Window SHALL verify the integrity and availability of its target data source (TSV) prior to state transitions. If the data is completely unavailable and recovery fails, it SHALL gracefully abort initialization without altering the `FSM.DRUM_WINDOW` state unpredictably.

#### Scenario: Safe Abortion on Fatal Data Loss
- **WHEN** the Drum Window attempts to open or initialize
- **AND** the required TSV file read encounters an unrecoverable failure (e.g. fatal locking, missing headers that cannot be written)
- **THEN** the Drum Window SHALL log an error and display an OSD message indicating failure to load data
- **AND** the Drum Window state SHALL remain `OFF`.
