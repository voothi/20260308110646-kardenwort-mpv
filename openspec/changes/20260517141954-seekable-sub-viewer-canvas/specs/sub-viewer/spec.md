## ADDED Requirements

### Requirement: Interactive Standalone Subtitle Playback
The system MUST allow launching mpv to play subtitle files directly on a static black background canvas without requiring a real video track.

#### Scenario: Drag-and-drop subtitle launching
- **WHEN** the user launches the sub-viewer shortcut passing a subtitle file as an argument
- **THEN** mpv SHALL open and render the subtitles on a fully seekable black background

### Requirement: Dynamic Timeline Bounding
The system MUST automatically adjust the playback timeline length to match the duration of the loaded subtitle file.

#### Scenario: Small subtitle files
- **WHEN** a subtitle file of 12 minutes is loaded
- **THEN** the mpv player seekbar total duration SHALL display exactly 12 minutes and 2 seconds
