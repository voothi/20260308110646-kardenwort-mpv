## ADDED Requirements

### Requirement: Immersion Engine - Adaptive Replay and Looping
The immersion engine must correctly handle subtitle replay and looping as per archives 20260504174809 and 20260504021904.

#### Scenario: Subtitle Replay in Autopause ON
- **WHEN** the `s` key is pressed during playback of a subtitle.
- **THEN** the subtitle should play to its end and then restart from its beginning for the configured number of repetitions.

#### Scenario: Subtitle Looping in Autopause OFF
- **WHEN** the `s` key is pressed while Autopause is OFF.
- **THEN** the current subtitle should loop indefinitely until interrupted.

### Requirement: Drum Mode - Navigation and Cursor Sync
Drum mode must maintain cursor synchronization and allow reliable navigation as per archives 20260504033538 and 20260502104026.

#### Scenario: Cursor Sync on Navigation
- **WHEN** navigating between subtitles in Drum Mode.
- **THEN** the yellow pointer and selection state must remain synchronized between the primary and secondary tracks.
