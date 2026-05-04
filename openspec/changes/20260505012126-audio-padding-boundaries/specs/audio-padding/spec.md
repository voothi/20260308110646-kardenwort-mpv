# Specification: Audio Padding

## ADDED Requirements

### Requirement: Configurable Audio Padding Start
The system SHALL provide a configuration option `audio_padding_start` (in ms) that defines a temporal offset to be applied before the start of a subtitle when seeking.

#### Scenario: Seeking to subtitle with start padding
- **GIVEN** `audio_padding_start` is set to 200ms
- **WHEN** the user seeks to a subtitle starting at 00:10.000
- **THEN** the player SHALL seek to 00:09.800 (10.0 - 0.2)

### Requirement: Configurable Audio Padding End
The system SHALL provide a configuration option `audio_padding_end` (in ms) that defines a temporal offset to be applied after the end of a subtitle when calculating autopause or loop boundaries.

#### Scenario: Autopausing with end padding
- **GIVEN** `audio_padding_end` is set to 500ms and `pause_padding` is 150ms
- **GIVEN** a subtitle ends at 00:15.000
- **WHEN** `time-pos` reaches 00:15.350 (15.0 + 0.5 - 0.15)
- **THEN** the system SHALL trigger a pause event

### Requirement: Minimum Seek Guard
The system SHALL ensure that any seek operation resulting from padding does not attempt to seek to a negative timestamp.

#### Scenario: Seeking near video start
- **GIVEN** `audio_padding_start` is set to 1000ms
- **WHEN** the user seeks to a subtitle starting at 00:00.500
- **THEN** the player SHALL seek to 00:00.000 (clamped at zero)

### Requirement: Replay Mode Independence
The system SHALL NOT apply `audio_padding_start` or `audio_padding_end` to the fixed-window "Flashback" Replay command (`s`).

#### Scenario: Replaying current position
- **GIVEN** `audio_padding_start` is set to 500ms
- **WHEN** the user triggers a 2000ms replay at 00:10.000
- **THEN** the player SHALL seek exactly to 00:08.000 (ignoring padding)
