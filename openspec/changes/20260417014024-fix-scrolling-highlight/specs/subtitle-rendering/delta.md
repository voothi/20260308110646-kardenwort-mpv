## ADDED Requirements

### Requirement: Precision-Aware Active Highlighting
The system SHALL ensure that the "active" subtitle (highlighted in white) remains consistently highlighted even during precise navigation or seek operations where the player position might land slightly before the official start time.

#### Scenario: Seeking to Subtitle Start
- **WHEN** the user seeks to a subtitle's start time using 'a' or 'd'
- **THEN** the subtitle SHALL be highlighted in its active state (white) immediately, even if the landing time is slightly outside the nominal range.

#### Scenario: Active Line Consistency
- **WHEN** in Standard or Drum (C) modes
- **THEN** the subtitle rendering SHALL follow the same highlighting logic as the Drum Window (Mode W), ensuring that the "focused" subtitle (returned by the centering logic) is always rendered in its active state.
