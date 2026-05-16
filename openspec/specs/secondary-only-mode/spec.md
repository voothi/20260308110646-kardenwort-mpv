# Secondary Only Mode

## Purpose
Allow users to focus on translation or secondary tracks while maintaining full behavioral synchronization with the primary language track.

## Requirements

### Requirement: Secondary Only Mode
The system SHALL provide a "Secondary Only" mode that displays the secondary subtitle track while hiding the primary track, while ensuring the FSM continues to process primary track data in the background.

#### Scenario: Enabling Secondary Only Mode
- **WHEN** user triggers `toggle-secondary-only`
- **THEN** primary subtitles are hidden from the OSD
- **THEN** secondary subtitles are displayed on the OSD
- **THEN** FSM auto-pause and navigation logic continue to function based on primary track timestamps

#### Scenario: Cycling Visibility to Secondary Only
- **WHEN** user cycles `toggle-sub-visibility` through states
- **THEN** the system SHALL transition to a state where only the secondary subtitle is visible
- **THEN** OSD feedback displays "Subtitles: ON" and "Secondary Only: ON" (or equivalent)
