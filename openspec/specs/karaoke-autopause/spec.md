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
The autopause mechanism MUST suppress pause triggers only for cross-card manual navigation transit and MUST preserve normal end-of-card pause behavior for inside-card movement.

#### Scenario: Cross-card rewind during Autopause ON
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** the user invokes `Shift+a` or `Shift+d` and the resulting transit crosses subtitle-card boundaries
- **THEN** `tick_autopause` MUST suppress boundary pauses during active transit inhibit
- **AND** suppression MUST end when transit completion is reached.

#### Scenario: Inside-card rewind during Autopause ON
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** user rewind/navigation remains within the active subtitle card
- **THEN** `tick_autopause` MUST continue normal phrase-end pause checks
- **AND** it MUST NOT treat this case as cross-card suppression transit.

#### Scenario: Space hold in Autopause ON + PHRASE uses temporary MOVIE flow
- **WHEN** `FSM.AUTOPAUSE == "ON"`
- **AND** immersion mode is `PHRASE`
- **AND** the user holds `Space`
- **THEN** boundary progression MUST use MOVIE-like seamless handover while the key is held
- **AND** when `Space` is released (including implicit release caused by multi-key hardware/mpv behavior), normal PHRASE end-of-card autopause MUST resume at the next valid boundary.

