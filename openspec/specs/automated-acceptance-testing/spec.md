# Capability: Automated Acceptance Testing

## Purpose
Enable the automated verification of system behavior against formal specifications via CLI-driven integration tests.

## Requirements

### Requirement: CLI-Driven Interaction
The system SHALL provide a mechanism to simulate user inputs (keyboard, mouse) from an external process.

#### Scenario: Simulating a keypress
- **WHEN** the external test runner sends a "keypress" command via IPC
- **THEN** the script SHALL respond as if the user pressed the corresponding physical key.

### Requirement: State Introspection
The script SHALL expose its internal state (FSM, Tracks, Hit-Zones) to external queries.

#### Scenario: Querying playback state
- **WHEN** the test runner queries the "playback-mode"
- **THEN** the system SHALL return the current value of the internal `FSM.MEDIA_STATE`.

### Requirement: Rendering Verification
The system SHALL support verification of visual elements via OSD overlay data inspection.

#### Scenario: Verifying highlight color
- **WHEN** a word is highlighted
- **THEN** the OSD overlay data SHALL contain the correct ASS color tag for that specific word.
