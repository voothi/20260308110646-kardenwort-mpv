## ADDED Requirements

### Requirement: Rewind Suppression Support
The system SHALL support temporary suppression of autopause during rewind operations without affecting the core pause-at-phrase/word behavior.

#### Scenario: Phrase pause suppressed during rewind
- **WHEN** autopause is suppressed due to a rewind operation
- **AND** a phrase completion occurs during the suppression period
- **THEN** the system SHALL NOT pause at the phrase completion
- **AND** the system SHALL resume normal phrase pausing after suppression expires

#### Scenario: Word pause suppressed during rewind
- **WHEN** autopause is suppressed due to a rewind operation
- **AND** a karaoke token transition occurs during the suppression period
- **THEN** the system SHALL NOT pause at the token transition
- **AND** the system SHALL resume normal word pausing after suppression expires

#### Scenario: Hold-to-play bypass takes precedence
- **WHEN** autopause is suppressed due to a rewind operation
- **AND** the user holds the SPACE key during the suppression period
- **THEN** the hold-to-play bypass SHALL continue to function
- **AND** playback SHALL continue uninterrupted
