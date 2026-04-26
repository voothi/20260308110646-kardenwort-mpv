# Specification Updates: Subtitle Rendering and Interactivity

## ADDED Requirements

### Requirement: Pure Manual Positioning
The subtitle rendering engine SHALL NOT apply automatic offsets or adjustments to the vertical position of subtitle tracks.

#### Scenario: User-Defined Stacking
- **GIVEN** Primary sub position is at 90 and Secondary sub position is at 80
- **WHEN** Drum Mode or OSD rendering is active
- **THEN** The tracks SHALL be rendered at exactly those positions (accounting for their own height) without the script attempting to "correct" or "safety-offset" the secondary track.

### Requirement: Character-Based Word Boundaries
All word-width calculations for hit-testing and selection highlights SHALL use character-aware iteration.

#### Scenario: Cyrillic Hit-Testing
- **GIVEN** A Russian word "Привет" (12 bytes, 6 characters)
- **WHEN** Calculating the width for selection zones
- **THEN** The system SHALL iterate exactly 6 times and apply width heuristics per character, ensuring the selection zone matches the visual glyphs.

### Requirement: Drum Mode Visibility Master
The Drum Mode (Mode C) toggle SHALL act as a master visibility control for custom OSD rendering.

#### Scenario: Practicing with Hidden Subtitles
- **GIVEN** Native subtitle visibility (`s` key) is OFF
- **WHEN** Drum Mode is toggled ON
- **THEN** The custom OSD rendering SHALL become visible, enabling interactive practice even when the native subtitle track is hidden from the player's perspective.
