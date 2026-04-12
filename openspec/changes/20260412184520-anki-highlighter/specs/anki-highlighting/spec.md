## ADDED Requirements

### Requirement: TSV Highlight Capture
The application SHALL allow the user to extract the currently selected text inside the Drum Window and commit it to a localized TSV database matching the media's base filename.

#### Scenario: Exporting a selected term
- **WHEN** the user selects text in the Drum Window and triggers the export binding (MBTN_MID)
- **THEN** the system extracts the literal selected string and a broadened context window (including surrounding subtitles, capped by max constraints), and appends/updates an Anki-compatible TSV row into the media's directory.

### Requirement: Sentence-Aware Context Extraction
The context extraction algorithm SHALL prioritize isolating complete sentences within the sliding subtitle window before applying any word-limit truncation.

#### Scenario: Capturing context at sentence boundaries
- **WHEN** a term is exported from a context that spans multiple sentences
- **THEN** the system identifies `.`, `!`, `?` marks surrounding the term and attempts to capture only the grammatically complete sentence, avoiding "leaking" text from previous or subsequent unrelated sentences.

### Requirement: Highlight Toggle Keybinding
The application SHALL bind `h` (and `р` for RU layout) to toggle the visual re-rendering scope of the highlights.

#### Scenario: Toggling Global Highlighting
- **WHEN** the user presses `h`
- **THEN** the rendering engine swaps between evaluating the TSV terms globally across all timeline elements and locally strictly to the original export timestamp.

### Requirement: Periodic Database Sync
The application SHALL periodically re-synchronize the in-memory highlight dictionary with the state of the physical TSV file.

#### Scenario: Real-time update from file edit
- **WHEN** the user or an external process modifies the TSV database file
- **THEN** within a configurable interval (5s), the player system reloads the file atomically (using `pcall` for safety) and refreshes all active subtitle viewports (Drum and Timeline) to reflect the new state.
