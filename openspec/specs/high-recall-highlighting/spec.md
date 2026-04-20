# High-Recall Highlighting

## Purpose
Ensure that saved vocabulary and phrases are accurately and persistently highlighted across all playback modes, utilizing deep contextual anchoring (Word-Token Intersection) to prevent spurious matches while maintaining high recall for fragmented subtitles.

## Requirements

### Requirement: Inter-Segment Sequence Matching
The highlighter engine SHALL be capable of verifying word sequences that are split across adjacent subtitle segments.

#### Scenario: Phrase split across two subtitles
- **WHEN** the term "falsch sind" is saved
- **AND** "falsch" is the last word of Subtitle 1
- **AND** "sind" is the first word of Subtitle 2
- **AND** the temporal gap between segments is less than or equal to **60.0 seconds** (Generous Inter-Segment Bridging)
- **THEN** both "falsch" and "sind" SHALL be highlighted in their respective segments

### Requirement: Windowed Sequence Verification
The engine SHALL verify phrase integrity by checking a ±3 word local "neighborhood" around any match candidate.
- This allows long paragraphs that exceed the display buffer to remain highlighted while still preventing common-word bleed (e.g., 'nur', 'die') in Global Mode.

#### Scenario: Verification neighborhood
- **WHEN** a match is found
- **THEN** neighbors are checked within ±3 words

### Requirement: Precision Neighborhood Verification (Token Intersection)
When Global Highlighting is active, the system SHALL perform a word-token intersection check against neighboring segments to ensure contextual validity.
- **Mechanism**: The engine SHALL scan neighboring segments (+/- `anki_neighbor_window`, default 5 lines).
- **Token Filtering**: It SHALL extract all word-character tokens of length >= 2, stripped of punctuation.
- **Match Threshold**: A highlight SHALL ONLY be rendered if at least one meaningful word from the neighborhood exists within the record's stored context (Word-Token Dictionary).
- **Match Integrity**: The matching process MUST use exact whole-word comparison (dictionary-based) to prevent substring collisions.
- **Self-Exclusion Rule**: The target term itself SHALL be explicitly excluded from the neighborhood check. A highlight requires at least one **additional** context word to be present in the neighborhood to establish validity.

### Requirement: Temporal Proximity for Multi-Segment Phrases
The engine SHALL join adjacent segments into a single match if the temporal gap between them is less than or equal to **60.0 seconds** (Standardized Bridging).

#### Scenario: 10s Gap Tolerance
- **WHEN** the term "falsch sind" is saved.
- **AND** Subtitle 2 starts 5.0 seconds after Subtitle 1 ends.
- **THEN** BOTH words SHALL remain highlighted as a unified phrase.

### Requirement: Deep Segment Peeking
The engine SHALL recursively traverse up to 5 adjacent subtitle segments to verify a phrase match.
- This ensures continuity for paragraphs that are heavily fragmented into single-word or short-phrase subtitles.

#### Scenario: Recursive traversal
- **WHEN** matching long phrases
- **THEN** up to 5 segments are checked

### Requirement: Single-Word Global Recall Exemption
To maintain maximum recall for core vocabulary, the proximity grounding system SHALL implement a hybrid strictness model.
- **Single-Word Match**: Terms consisting of only one logical word SHALL be exempt from strict neighborhood verification when `anki_context_strict` is disabled.
- **Phrase Match**: Multi-word phrases SHALL remain subject to strict neighborhood verification to prevent coincidental matching across unrelated scenes.

### Requirement: Weighted Temporal Highlight Expansion
The highlight engine MUST apply temporal window expansion using a surplus-only weighted formula to ensure stability for long phrases without excessive buffer bloat.
- **Base Buffer**: `anki_local_fuzzy_window` (e.g. 10.0s).
- **Expansion Rate**: 0.5s per word.
- **Application Threshold**: Expansion applies ONLY to words beyond the 10th word in a term.
- **Formula**: `Window = Base + (max(0, WordCount - 10) * ExpansionRate)`.

#### Scenario: Expanding window for a long phrase
- **WHEN** a 12-word phrase is rendered
- **THEN** the highlight window SHALL be `Base + (2 * 0.5) = Base + 1.0s`.
- **AND** a 10-word phrase SHALL have NO expansion (`Base + 0.0s`).

### Requirement: Cloze-Aware Context Grounding
The context cleaning engine SHALL prioritize the preservation of textual content within Anki cloze deletions during neighborhood verification.
- **Behavior**: While standard ASS tags and square-bracket metadata (e.g. `[Musik]`) are stripped from context dictionaries, content inside `{{c#::...}}` tags MUST be extracted and preserved as searchable tokens.

#### Scenario: Contextual Anchor found
- **WHEN** `anki_global_highlight` is enabled.
- **AND** a textual match is found in a segment.
- **THEN** the engine scans +/- 5 neighbor lines.
- **IF** any word from those neighbors exists in the Anki context.
- **THEN** the highlight SHALL be rendered.

### Requirement: Performance Caching
The engine SHALL cache word lists and cleaned text for all highlight terms on first access.
- Rendering latency SHALL NOT increase significantly when hundreds of terms are active.

#### Scenario: Caching on access
- **WHEN** a term is accessed
- **THEN** its metadata is cached

### Requirement: Self-Contextualization
The engine SHALL verify word neighbors against both the original `SentenceSource` (context) and the `WordSource` (term) itself.
- This allows long, multi-sentence captures to remain active even if only one sentence was saved as the primary context.

#### Scenario: Multi-source verification
- **WHEN** verifying context
- **THEN** both sentence and word sources are checked

### Requirement: Adaptive Punctuation Rendering
The engine SHALL surgically isolate word bodies from their surrounding punctuation marks during rendering, based on match context.
- **Single-Word Mode**: If a highlight corresponds to a single vocabulary word, punctuation marks SHALL remain uncolored (base subtitle color).
- **Phrase Continuity Mode**: If a highlight corresponds to a multi-word phrase, internal punctuation marks SHALL be colored.
- **Multi-Match Priority**: If a word is covered by both a single-word card and a phrase highlight, **Phrase Continuity Mode** SHALL take precedence.

#### Scenario: Word overlapped by a phrase
- **WHEN** the term "ehrlich," exists in Anki as a single-word card
- **AND** the term "Mal ehrlich," exists in Anki as a multi-word phrase
- **THEN** both terms SHALL be aggregated, and the comma after "ehrlich" SHALL be colored green (Phrase Continuity Mode).

### Requirement: Clean Boundary Capture
The capture engine SHALL automatically strip leading and trailing punctuation/whitespace from any text copied to the clipboard or exported to Anki tags.
- Internal punctuation (within phrases) SHALL be preserved.

#### Scenario: Exporting a word with trailing punctuation
- **WHEN** the user middle-clicks on the subtitle word "Umbruch."
- **THEN** the term "Umbruch" SHALL be saved to the Anki TSV file (dot stripped).

### Requirement: Configurable Highlight Bolding
The rendering engine SHALL respect the `anki_highlight_bold` configuration option when displaying vocabulary highlights in all active renderers.

#### Scenario: Bold highlights enabled in Drum Window
- **WHEN** `anki_highlight_bold` is set to `yes`
- **AND** a word is rendered in the Drum Window viewport
- **AND** the word is identified as an active Anki highlight
- **THEN** the system SHALL wrap the highlighted segment in ASS bold tags `{\b1}` and `{\b0}`.

### Requirement: Metadata-Tolerant Context Matching
The highlight engine SHALL ignore or skip metadata tags (e.g., `[musik]`) when checking adjacent neighbors during strict context verification if those tags have been stripped from the stored context field.

#### Scenario: Highlighting a word next to a metadata tag
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **AND** the word `Netto` was saved from `[UMGEBUNG] Netto`
- **AND** the stored context in Anki is only `Netto` (metadata stripped)
- **WHEN** the user plays the subtitle `[UMGEBUNG] Netto`
- **THEN** the word `Netto` SHALL remain highlighted despite `[UMGEBUNG]` being missing from the stored context.

### Requirement: Symbol-Agnostic Neighbor Matching
The strict context neighbor check MUST look past symbol-only tokens (dashes, slashes, brackets) to determine if a neighboring word is present in the recorded context.

#### Scenario: Highlighting compound words
- **WHEN** Checking neighbor for "Netto" in "Netto/Globus"
- **THEN** The engine MUST skip "/" and use "Globus" as the right-hand neighbor for context validation.

### Requirement: High-Fidelity Range Reconstruction
The reconstruction engine (Copy/Anki Export) MUST preserve the exact character sequence, including internal punctuation and original whitespace tokens, when a range of contiguous words is selected from a subtitle segment.

#### Scenario: Copying a phrase with internal punctuation
- **WHEN** the user selects a range of words in the Drum Window
- **AND** the source segment contains "Hören, ob" within that range
- **THEN** the reconstructed text SHALL contain "Hören, ob" (comma and space preserved)
