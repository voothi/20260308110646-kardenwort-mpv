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

### Requirement: Secondary Sub Only Label Consistency
The OSD label for this mode SHALL use the canonical text `Secondary Sub Only: ON/OFF` to avoid ambiguity with generic secondary subtitle visibility messaging.

#### Scenario: Toggling the mode ON and OFF
- **WHEN** the user triggers `toggle-secondary-only`
- **THEN** enabling SHALL display `Secondary Sub Only: ON`
- **AND** disabling SHALL display `Secondary Sub Only: OFF`.

### Requirement: Secondary Track Cycle Guard While Secondary Sub Only Is Active
While `Secondary Sub Only` mode is active, secondary-track cycling (`cycle-sec-sid`, bound to `Shift+C`) SHALL be blocked to prevent contradictory overlay states such as mode ON together with `Secondary Sub: OFF`.

#### Scenario: Attempting to cycle secondary sid in Secondary Sub Only mode
- **GIVEN** `Secondary Sub Only` mode is ON
- **WHEN** the user triggers `cycle-sec-sid` (`Shift+C`)
- **THEN** the system SHALL display `X`
- **AND** the currently selected secondary subtitle track SHALL remain unchanged.
