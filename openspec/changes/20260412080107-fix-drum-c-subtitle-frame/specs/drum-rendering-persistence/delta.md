## ADDED Requirements

### Requirement: Drum Mode OSD Styling Persistence
The Drum Mode (C) subtitle overlay must retain its background-box styling even when other OSD-based interfaces (like Search) are active.

#### Scenario: Active Search in Drum Mode
- **WHEN** Drum Mode (C) is ON and the Global Search UI (Ctrl+f) is opened.
- **THEN** The subtitles rendered by `drum_osd` must continue to display with a background box (dark frame).
