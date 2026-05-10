## ADDED Requirements

### Requirement: Rewind Autopause Suppression
The system SHALL temporarily suppress autopause for the duration of the rewind when a seek operation crosses subtitle boundaries via `Shift+a` or `Shift+d` keybindings. The `s` key (replay) does NOT suppress autopause since it stays within the same subtitle.

#### Scenario: No suppression on subtitle replay
- **WHEN** the user presses `s` to replay the current subtitle
- **THEN** the system SHALL NOT suppress autopause
- **AND** the system SHALL pause at phrase or word boundaries as configured

#### Scenario: Suppression on backward seek crossing subtitle boundaries
- **WHEN** the user presses `Shift+a` to seek backward
- **AND** the seek crosses subtitle boundaries (current subtitle index changes)
- **THEN** the system SHALL calculate the rewind duration as the time difference before and after the seek
- **AND** the system SHALL suppress autopause for that duration
- **AND** the system SHALL NOT pause at phrase or word boundaries during the suppression period

#### Scenario: No suppression on backward seek within same subtitle
- **WHEN** the user presses `Shift+a` to seek backward
- **AND** the seek stays within the same subtitle (current subtitle index does not change)
- **THEN** the system SHALL NOT suppress autopause
- **AND** the system SHALL pause at phrase or word boundaries as configured

#### Scenario: Suppression on forward seek crossing subtitle boundaries
- **WHEN** the user presses `Shift+d` to seek forward
- **AND** the seek crosses subtitle boundaries (current subtitle index changes)
- **THEN** the system SHALL calculate the rewind duration as the time difference before and after the seek
- **AND** the system SHALL suppress autopause for that duration
- **AND** the system SHALL NOT pause at phrase or word boundaries during the suppression period

#### Scenario: No suppression on forward seek within same subtitle
- **WHEN** the user presses `Shift+d` to seek forward
- **AND** the seek stays within the same subtitle (current subtitle index does not change)
- **THEN** the system SHALL NOT suppress autopause
- **AND** the system SHALL pause at phrase or word boundaries as configured

#### Scenario: Autopause restoration after suppression
- **WHEN** the suppression period expires
- **THEN** the system SHALL restore normal autopause behavior
- **AND** the system SHALL pause at the next phrase or word boundary as configured

#### Scenario: Multiple boundary-crossing seeks extend suppression
- **WHEN** the user performs multiple seek operations that cross subtitle boundaries before the suppression period expires
- **THEN** the system SHALL extend the suppression period based on the latest seek duration
- **AND** the suppression period SHALL be set to `current_time + seek_duration`

#### Scenario: Suppression does not affect normal playback
- **WHEN** playback continues without rewind operations
- **THEN** the system SHALL maintain normal autopause behavior
- **AND** the system SHALL pause at phrase or word boundaries as configured
