# Spec: Drum Mode OSD Styling Persistence

## Context
In the project's minimalist and premium design, readability and visual consistency are paramount. This capability ensures that core visual elements like the Drum Mode subtitle frame remain stable even when transient UI components like the search bar are active.

## Requirements

### Requirement: Drum Mode OSD Styling Persistence
The Drum Mode (C) subtitle overlay must retain its localized background-box styling even when other OSD-based interfaces (like Search) are active. This styling SHALL be explicitly controlled by script parameters.

#### Scenario: Active Search in Drum Mode
- **WHEN** Drum Mode (C) is ON and the Global Search UI (Ctrl+f) is opened.
- **THEN** The subtitles rendered by `drum_osd` must continue to display with a background box (dark frame).

#### Scenario: Background Opacity Control
- **WHEN** the `drum_bg_opacity` configuration is adjusted
- **THEN** the system SHALL immediately update the `\4a` (background alpha) of the Drum Mode OSD overlay to match, independent of the global `osd-back-color` transparency.
