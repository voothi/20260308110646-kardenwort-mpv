## ADDED Requirements

### Requirement: External Subtitle Dependency Enforcement
The system SHALL validate the existence of external subtitle file paths before activating advanced processing features (Drum Mode, Search HUD, Drum Window).

#### Scenario: Activating search on embedded track
- **WHEN** the user tries to open the Search HUD while using only embedded subtitles
- **THEN** the system SHALL display "Requires external subtitle files" and remain in the current state.
