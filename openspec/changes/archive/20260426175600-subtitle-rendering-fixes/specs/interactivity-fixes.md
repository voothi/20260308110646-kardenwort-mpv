# Specification Updates: Subtitle Rendering and Interactivity

## ADDED Requirements

### Requirement: Safety-Aware Positioning
The subtitle rendering engine SHALL apply automatic offsets to the secondary subtitle track if its manual position would cause it to overlap with the primary track.

#### Scenario: Collision Prevention
- **GIVEN** Primary sub position is at 90 and Secondary sub position is at 80 (bottom half)
- **WHEN** Drum Mode or OSD rendering is active
- **THEN** The system SHALL calculate a safety offset based on the primary track's height and apply it to the secondary track to ensure legibility, while still allowing the user's relative adjustments (`r/t`) to be reflected.

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
