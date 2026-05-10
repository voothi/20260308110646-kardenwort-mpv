## ADDED Requirements

### Requirement: Rewind Autopause Suppression
The system SHALL temporarily suppress autopause for the duration of the rewind when a rewind operation is performed via `s`, `Shift+a`, or `Shift+d` keybindings.

#### Scenario: Suppression on subtitle replay
- **WHEN** the user presses `s` to replay the current subtitle
- **THEN** the system SHALL calculate the rewind duration as `current_time - subtitle_start_time`
- **AND** the system SHALL suppress autopause for that duration
- **AND** the system SHALL NOT pause at phrase or word boundaries during the suppression period

#### Scenario: Suppression on backward seek
- **WHEN** the user presses `Shift+a` to seek backward
- **THEN** the system SHALL calculate the rewind duration as the time difference before and after the seek
- **AND** the system SHALL suppress autopause for that duration
- **AND** the system SHALL NOT pause at phrase or word boundaries during the suppression period

#### Scenario: Suppression on forward seek
- **WHEN** the user presses `Shift+d` to seek forward
- **THEN** the system SHALL calculate the rewind duration as the time difference before and after the seek
- **AND** the system SHALL suppress autopause for that duration
- **AND** the system SHALL NOT pause at phrase or word boundaries during the suppression period

#### Scenario: Autopause restoration after suppression
- **WHEN** the suppression period expires
- **THEN** the system SHALL restore normal autopause behavior
- **AND** the system SHALL pause at the next phrase or word boundary as configured

#### Scenario: Multiple rewinds extend suppression
- **WHEN** the user performs multiple rewind operations before the suppression period expires
- **THEN** the system SHALL extend the suppression period based on the latest rewind duration
- **AND** the suppression period SHALL be set to `current_time + rewind_duration`

#### Scenario: Suppression does not affect normal playback
- **WHEN** playback continues without rewind operations
- **THEN** the system SHALL maintain normal autopause behavior
- **AND** the system SHALL pause at phrase or word boundaries as configured
