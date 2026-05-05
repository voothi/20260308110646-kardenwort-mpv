## ADDED Requirements

### Requirement: Descriptive Minimalist Labeling
All OSD feedback for system state changes MUST include a descriptive prefix identifying the setting being modified, followed by the new state value.

#### Scenario: Toggling Drum Mode
- **WHEN** the user toggles Drum Mode via the `c` key
- **THEN** the OSD MUST display `Drum Mode: ON` or `Drum Mode: OFF` instead of a standalone `ON`/`OFF`.

### Requirement: Shortened Labels for Information Density
Long descriptive labels MUST be shortened to maintain a clean UI without sacrificing clarity.

#### Scenario: Cycling Secondary Subtitle Position
- **WHEN** the user cycles secondary subtitle positions
- **THEN** the OSD MUST use the prefix `Secondary Sub Pos:` instead of the full `Secondary Subtitle Position:`.

### Requirement: Context-Aware Clipboard Feedback
Clipboard confirmation messages MUST indicate the source of the extracted text when multiple contexts exist.

#### Scenario: Copying from Drum Window
- **WHEN** the user copies a word or range while the Drum Window is active
- **THEN** the OSD MUST display `DW Copied [Track]: [Snippet]` to distinguish it from regular playback copying.
