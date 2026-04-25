## MODIFIED Requirements

### Requirement: Dynamic Visibility Suppression
The system SHALL periodically suppress native mpv subtitles ONLY for tracks currently being rendered via a custom OSD-based subtitle mode (SRT-OSD, Drum Mode, or Drum Window).
- Native rendering SHALL be permitted to persist for ASS/SSA tracks even when OSD modes are active for other tracks, ensuring preservation of complex styling.
- All tracks SHALL be suppressed if the Drum Window is active to ensure a clean UI.

#### Scenario: Hybrid Rendering (SRT-OSD + Native ASS)
- **GIVEN** a primary SRT track using OSD styling and a secondary ASS track
- **WHEN** the system is in standard playback mode
- **THEN** the system SHALL force `sub-visibility` to `false` (SRT suppressed)
- **AND** it SHALL allow `secondary-sub-visibility` to match the user's preference (ASS displayed natively).
