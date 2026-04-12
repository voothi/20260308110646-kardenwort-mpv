# Spec: Navigation Auto-Repeat (Modified)

## ADDED Requirements

### Requirement: Immediate Startup Activation
The system SHALL ensure that subtitle navigation keys (`a`, `d`, `ф`, `в`) are functional as soon as the video playback begins, assuming subtitle tracks are available.

#### Scenario: Navigating immediately after file load
- **WHEN** the user starts a video with external subtitles
- **THEN** within 500ms of the first frame, pressing `d` SHALL immediately perform a subtitle seek, even if no special modes (Drum/Window) have been activated.
