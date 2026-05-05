## ADDED Requirements

### Requirement: Cyclic Subtitle Navigation
The system SHALL support cyclic (wrap-around) navigation between the first and last subtitles using the previous/next subtitle commands.

#### Scenario: Wrap-around from first to last
- **WHEN** the playhead is at the first subtitle (index 1) and the `lls-seek_prev` command is executed
- **THEN** the system SHALL seek to the last subtitle in the track

#### Scenario: Wrap-around from last to first
- **WHEN** the playhead is at the last subtitle and the `lls-seek_next` command is executed
- **THEN** the system SHALL seek to the first subtitle in the track

### Requirement: Boundary Stability in Phrases Mode
The system SHALL NOT jump to the last subtitle automatically when replaying or seeking to the first subtitle in Phrases mode.

#### Scenario: Replaying first subtitle
- **WHEN** the user replays the first subtitle
- **THEN** the system SHALL remain focused on the first subtitle index and NOT jump to the end of the track

### Requirement: OSC Synchronization
The system SHALL synchronize the active subtitle index when the user seeks manually via the native `mpv` OSC timeline.

#### Scenario: Seeking via OSC Timeline
- **WHEN** the user clicks on the `mpv` OSC timeline to jump to a different part of the media
- **THEN** the system SHALL detect the jump, update the `ACTIVE_IDX`, and suppress the "Jerk Back" logic for the duration of the navigation cooldown
