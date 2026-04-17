# High-Recall Highlighting

## Requirements

### Requirement: Inter-Segment Sequence Matching
The highlighter engine SHALL be capable of verifying word sequences that are split across adjacent subtitle segments.

#### Scenario: Phrase split across two subtitles
- **WHEN** the term "falsch sind" is saved
- **AND** "falsch" is the last word of Subtitle 1
- **AND** "sind" is the first word of Subtitle 2
- **AND** Subtitle 2 starts within 1.5 seconds of Subtitle 1 ending
- **THEN** both "falsch" and "sind" SHALL be highlighted in their respective segments

### Requirement: Windowed Sequence Verification
The engine SHALL verify phrase integrity by checking a ±3 word local "neighborhood" around any match candidate.
- This allows long paragraphs that exceed the display buffer to remain highlighted while still preventing common-word bleed (e.g., 'nur', 'die') in Global Mode.

### Requirement: Temporal Proximity for Multi-Segment Phrases
The engine SHALL only join adjacent segments into a single match if the temporal gap between them is less than or equal to 1.5 seconds.
- This accommodates natural pauses in news reader speech while maintaining phrase integrity.

### Requirement: Deep Segment Peeking
The engine SHALL recursively traverse up to 5 adjacent subtitle segments to verify a phrase match.
- This ensures continuity for paragraphs that are heavily fragmented into single-word or short-phrase subtitles.

### Requirement: Adaptive Temporal Highlight Window
The engine SHALL calculate the fuzzy matching window dynamically based on the length of the saved term.
- Base window: `lls-anki_local_fuzzy_window` (e.g., 10s).
- Growth: +0.5 seconds for every word beyond the 10th word.
- Goal: Ensure long paragraphs stay highlighted for the duration of their reading time.

### Requirement: Performance Caching
The engine SHALL cache word lists and cleaned text for all highlight terms on first access.
- Rendering latency SHALL NOT increase significantly when hundreds of terms are active.

### Requirement: Self-Contextualization
The engine SHALL verify word neighbors against both the original `SentenceSource` (context) and the `WordSource` (term) itself.
- This allows long, multi-sentence captures to remain active even if only one sentence was saved as the primary context.

### Requirement: Adaptive Punctuation Rendering
The engine SHALL surgically isolate word bodies from their surrounding punctuation marks during rendering, based on match context.
- **Single-Word Mode**: If a highlight corresponds to a single vocabulary word, punctuation marks SHALL remain uncolored (base subtitle color) to provide a clean study interface.
- **Phrase Continuity Mode**: If a highlight corresponds to a multi-word phrase or paragraph, internal punctuation marks SHALL be colored to maintain visual flow and prevent "holes" in the highlight blocks.
- **Multi-Match Priority**: If a word is covered by both a single-word card and a phrase highlight, **Phrase Continuity Mode** SHALL take precedence.

#### Scenario: Word overlapped by a phrase
- **WHEN** the term "ehrlich," exists in Anki as a single-word card
- **AND** the term "Mal ehrlich," exists in Anki as a multi-word phrase
- **THEN** both terms SHALL be aggregated, and the comma after "ehrlich" SHALL be colored green (Phrase Continuity Mode).

### Requirement: Clean Boundary Capture
The capture engine SHALL automatically strip leading and trailing punctuation/whitespace from any text copied to the clipboard or exported to Anki tags.
- This ensures that word-boundaries do not pollute the flashcard database, maintaining high dictionary matching rates.
- Internal punctuation (within phrases) SHALL be preserved.

#### Scenario: Exporting a word with trailing punctuation
- **WHEN** the user middle-clicks on the subtitle word "Umbruch."
- **THEN** the term "Umbruch" SHALL be saved to the Anki TSV file (dot stripped).


### Requirement: Configurable Highlight Bolding
The rendering engine SHALL respect the `anki_highlight_bold` configuration option when displaying vocabulary highlights in all active renderers, specifically the classic Drum Mode and the unified Drum Window.

#### Scenario: Bold highlights enabled in Drum Window
- **WHEN** `anki_highlight_bold` is set to `yes`
- **AND** a word is rendered in the Drum Window viewport
- **AND** the word is identified as an active Anki highlight
- **THEN** the system SHALL wrap the highlighted segment in ASS bold tags `{\b1}` and `{\b0}`, ensuring the bolding is visually distinct regardless of the line's base font weight.

#### Scenario: Bold highlights disabled
- **WHEN** `anki_highlight_bold` is set to `no`

### Requirement: Metadata-Tolerant Context Matching
The highlight engine SHALL ignore or skip metadata tags (e.g., `[musik]`) when checking adjacent neighbors during strict context verification if those tags have been stripped from the stored context field.

#### Scenario: Highlighting a word next to a metadata tag
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **AND** the word `Netto` was saved from `[UMGEBUNG] Netto`
- **AND** the stored context in Anki is only `Netto` (metadata stripped)
- **WHEN** the user plays the subtitle `[UMGEBUNG] Netto`
- **THEN** the word `Netto` SHALL remain highlighted despite `[UMGEBUNG]` being missing from the stored context.
 
+### Requirement: Symbol-Agnostic Neighbor Matching
+The strict context neighbor check MUST look past symbol-only tokens (dashes, slashes, brackets) to determine if a neighboring word is present in the recorded context.
+
+#### Scenario: Highlighting compound words
+- **WHEN** Checking neighbor for "Netto" in "Netto/Globus"
+- **THEN** The engine MUST skip "/" and use "Globus" as the right-hand neighbor for context validation.
+
+#### Scenario: Highlighting bracketed context
+- **WHEN** Checking neighbor for "Große" in "Donau) Große"
+- **THEN** The engine MUST recognize "Donau" (even with the bracket) as a valid neighbor.
+
