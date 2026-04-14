# anki-highlighting Specification

## Purpose
TBD - created by archiving change 20260412184520-anki-highlighter. Update Purpose after archive.
## Requirements
### Requirement: TSV Highlight Capture
The application SHALL allow the user to extract the currently selected text inside the Drum Window and commit it to a localized TSV database matching the media's base filename.

#### Scenario: Exporting a selected term
- **WHEN** the user selects text in the Drum Window and triggers the export binding (MBTN_MID)
- **THEN** the system extracts the literal selected string and a broadened context window (including surrounding subtitles, capped by max constraints), and appends/updates an Anki-compatible TSV row into the media's directory.

### Requirement: Sentence-Aware Context Extraction
The context extraction algorithm SHALL prioritize isolating complete sentences within the sliding subtitle window before applying any word-limit truncation. **The algorithm MUST identify sentence boundaries (punctuation) relative to the END of the selected term to ensure multi-sentence selections are fully encompassed.**

#### Scenario: Capturing context for multi-sentence terms
- **WHEN** a term containing punctuation (e.g., "Umbruch. Während") is exported
- **THEN** the system searches for the preceding punctuation starting from the term's start, and the following punctuation starting from the term's end, ensuring both sentences are included in the result.

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

### Requirement: Split-Term Multi-Word Highlighting
The visual highlighting system SHALL support non-contiguous subset matching for multi-word terms imported from the TSV database (e.g., terms that contain spaces). If the constituent words of a registered multi-word term are detected scattered but fully present within a specific localized context boundary (such as the same subtitle element/line), those words SHALL be highlighted with a distinctive "split select color" to signify their association. The system MUST evaluate local inclusion by projecting the term's timestamp against the FULL span of the subtitle (`start_time` to `end_time`) rather than a single point to prevent failures on long or multi-line subtitles. The contextual validation (`Options.anki_context_strict`) MUST use strict, word-bounded analysis to prevent substring false positives, and sequence matching MUST abort safely if expected words are entirely missing.

#### Scenario: Contiguous highlighting takes precedence
- **WHEN** a multi-word TSV term exists that can be matched as a single exact, contiguous string within the text
- **AND** the word sequence exactly corresponds without interruptions or missing words
- **THEN** it SHALL be rendered in the standard saved orange highlight.

#### Scenario: Successful application of the split highlight
- **WHEN** a multi-word TSV term (like "mache auf") exists in the TSV
- **AND** both "mache" and "auf" appear separated within the same subtitle text block
- **THEN** both individual words SHALL be styled using the `split_select_color` (which defaults to a purple color if unset).

#### Scenario: Incomplete presence disables split highlight
- **WHEN** a multi-word TSV term exists in the TSV (e.g., "mache auf")
- **AND** only one of the constituent words ("mache") is present in the subtitle line while the others are absent
- **THEN** no split highlight SHALL be applied to that single word.

#### Scenario: Missing relative word invalidates sequence match
- **WHEN** a multi-word TSV term is partially contiguous, but the expected consecutive word is absent from the subtitle block or gap range
- **THEN** the system SHALL immediately invalidate the contiguous sequence matching logic and fall-back to split matching.

#### Scenario: Proper split subset identification
- **WHEN** a multi-word TSV term is processed for split matching (e.g. "ist die Anwohner")
- **AND** intermediate generic words (e.g. "die") occur multiple times within the same context
- **THEN** the system SHALL calculate the shortest sequential span of the term's elements matching their original order, restricting the highlight strictly to those valid subsets and preventing false coloration on earlier or unrelated instances of those words (e.g. "die Geräte").

#### Scenario: Split phrase synchronization across wide clusters
- **WHEN** a split multi-word term bridges an extremely long span of dialogue over many subtitle events (e.g. "Beruf ... da")
- **THEN** the system SHALL securely scan a sufficient window of surrounding subtitle chunks (e.g. `[-15, +15]`) to capture scattered components.
- **AND** the system SHALL automatically augment the fuzzy temporal validity constraint to span exactly that outer limit natively, to ensure that words located at the far extremities of the phrase correctly inherit the temporal validity initially recorded for the first word.

### Requirement: Configurable Split Selection Color
The user SHALL be able to configure the specific hex color used for split-term highlighting via their player configuration.

#### Scenario: Custom split select color application
- **WHEN** the user provides `split_select_color=#123456` in `mpv.conf`
- **THEN** the rendering system uses this specific color instead of the default purple hex for split words.


