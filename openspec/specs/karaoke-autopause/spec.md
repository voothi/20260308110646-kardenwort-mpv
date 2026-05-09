# karaoke-autopause Specification

## Purpose
TBD - created by archiving change 20260309002123-release-v1-0-0. Update Purpose after archive.
## Requirements
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

### Requirement: Manual Navigation Suppression
The autopause mechanism MUST NOT interrupt playback when the user is actively navigating via subtitle-relative seek commands.

#### Scenario: Rewind during Autopause ON
- **WHEN** `FSM.AUTOPAUSE == "ON"`.
- **AND** The user invokes `Shift+a` or `Shift+d`.
- **THEN** The `tick_autopause` loop MUST return immediately without pausing, regardless of playhead position relative to subtitle boundaries.
- **AND** The inhibition MUST remain active until the seek command completes and the `nav_cooldown` period expires.

