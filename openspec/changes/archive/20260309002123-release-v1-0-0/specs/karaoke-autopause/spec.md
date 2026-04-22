## ADDED Requirements

### Requirement: End of Phrase Pause
The system SHALL pause playback only when a complete sentence or phrase has finished.

#### Scenario: Phrase completion
- **WHEN** the current subtitle line ends
- **THEN** the system SHALL pause playback.

### Requirement: Word by Word Pause
The system SHALL support pausing at individual word transitions when karaoke tags (`{\c}`) are present in the subtitle track.

#### Scenario: Karaoke token transition
- **WHEN** a new karaoke token starts
- **THEN** the system SHALL pause playback.

### Requirement: Hold-to-Play Bypass
The system SHALL allow the user to bypass all pause points by holding a specific key.

#### Scenario: Bypassing pauses
- **WHEN** the user holds the SPACE key
- **THEN** playback SHALL continue uninterrupted through all scheduled pause points.
