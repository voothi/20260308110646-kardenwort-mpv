# anki-highlighting Specification

## Purpose
This specification defines the high-precision grounding and rendering architecture for subtitle-locked highlights in the Drum Window. It ensures mining records are anchored to their exact scene context using a multi-coordinate system, providing flicker-free visual feedback across contiguous and non-contiguous phrases.
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

### Requirement: Multi-Pivot Grounding & Resiliency
The identifies engine MUST anchor mining records using a multi-pivot coordinate system (`LineOffset:WordIndex:TermPos`) for every word in a selection. The system SHALL prioritize absolute scene-locking based on these coordinates but MUST implement "Fuzzy Healing" fallbacks to maintain visual persistence if a subtitle index becomes outdated (e.g., due to file edits). To prevent coordinate drift at segment boundaries, a mandatory temporal epsilon of +1ms SHALL be applied to all exported timestamps.

#### Scenario: Absolute scene-locking with identical words
- **WHEN** multiple identical words appear in an episode
- **AND** `anki_global_highlight` is disabled
- **THEN** the system MUST use the L:W:T coordinates to highlight ONLY the specific word occurrence associated with the mining record.

#### Scenario: Resiliency to index mismatch
- **WHEN** a subtitle file is modified, causing a stored index to point to an incorrect coordinate
- **THEN** the engine SHALL fallback to a neighboring context check for contiguous terms and a "Shortest Sequential Span" search for split terms to re-locate and highlight the phrase.

### Requirement: Split-Term Multi-Word Highlighting
The visual highlighting system SHALL support non-contiguous subset matching for multi-word terms imported from the TSV database (e.g., terms that contain spaces). If the constituent words of a registered multi-word term are detected scattered but fully present within a specific localized context boundary, those words SHALL be highlighted with a distinctive "split select color" to signify their association. The system MUST evaluate local inclusion by projecting the term's timestamp against the FULL span of the subtitle (`start_time` to `end_time`) rather than a single point to prevent failures on long or multi-line subtitles. The contextual validation (`Options.anki_context_strict`) MUST use strict, word-bounded analysis to prevent substring false positives, and sequence matching MUST abort safely if expected words are entirely missing. Additionally, the system SHALL calculate the nesting depth of split-terms independently from contiguous terms. When a word overlaps with both contiguous and split terms simultaneously, it SHALL be rendered using a distinct "mixed" color palette (`anki_mix_depth_1/2/3`) representing the intersection. **The visual intent of split-matching SHALL be linked to the "Cool Path" (Neon Pink selection transitions to Purple match).**

#### Scenario: Contiguous highlighting takes precedence when pure
- **WHEN** a multi-word TSV term exists that can be matched as a single exact, contiguous string within the text
- **AND** it does not overlap with any split terms
- **THEN** it SHALL be rendered in the standard saved orange highlight based on its contiguous nesting depth.

#### Scenario: Pure split highlighting
- **WHEN** a multi-word TSV term exists in the TSV as non-contiguous
- **AND** the words do not overlap with any orange contiguous terms
- **THEN** the words SHALL be styled using the `anki_split_depth_X` color palette based on split nesting depth.

#### Scenario: Mixed intersection highlighting
- **WHEN** a word is a member of BOTH an orange contiguous saved term AND a purple split saved term
- **THEN** the system SHALL recognize the intersection
- **AND** it SHALL apply a mixed-color format (`anki_mix_depth_X`) determined by the combined depth of the intersection, ensuring the dual-membership is visually distinct.

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
- **THEN** the system SHALL securely scan a configurable window of surrounding subtitle chunks (default `+/- 35 lines`) to capture scattered components.
- **AND** the system SHALL automatically augment the temporal validity constraint up to a configurable limit (default `60.0s`) to ensure scattered components are correctly unified.

### Requirement: Configurable Split Selection Color
The user SHALL be able to configure the specific hex color used for split-term highlighting via their player configuration.

#### Scenario: Custom split select color application
- **WHEN** the user provides `split_select_color=#123456` in `mpv.conf`
- **THEN** the rendering system uses this specific color instead of the default purple hex for split words.

### Requirement: German UTF-8 Localization
The normalization engine MUST accurately map German uppercase umlauts and sharp S to their lowercase equivalents to support case-insensitive matching in German media.

#### Scenario: Normalizing German words
- **WHEN** Normalizing "Große" or "Änderung"
- **THEN** The engine MUST produce "große" and "änderung".

