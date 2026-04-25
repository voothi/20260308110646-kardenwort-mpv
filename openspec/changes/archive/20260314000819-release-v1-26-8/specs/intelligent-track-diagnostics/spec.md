## ADDED Requirements

### Requirement: Codec-Aware Track Cycling Feedback
The system SHALL identify when a user attempts to cycle subtitles on a structurally singular track (like a merged ASS file) and provide descriptive feedback instead of a generic status.

#### Scenario: Cycling single ASS track
- **WHEN** the user cycles secondary subtitles on a single ASS track
- **THEN** the system SHALL display "Secondary Subtitles: Managed internally by ASS styling".

#### Scenario: Cycling single SRT track
- **WHEN** the user cycles secondary subtitles on a single SRT track
- **THEN** the system SHALL display "Only 1 track available".
