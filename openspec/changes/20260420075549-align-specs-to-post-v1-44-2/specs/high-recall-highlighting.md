# High-Recall Highlighting

## Purpose
Ensure that saved vocabulary and phrases are accurately and persistently highlighted across all playback modes, utilizing deep contextual anchoring (Word-Token Intersection) to prevent spurious matches while maintaining high recall for fragmented subtitles.

## Requirements

### Requirement: Generous Inter-Segment Bridging
The highlighter engine SHALL be capable of verifying word sequences that are split across adjacent subtitle segments, even during slow speech patterns.
- **Temporal Threshold**: The system SHALL treat segments as contiguous for phrase matching if the temporal gap between them is less than or equal to **60.0 seconds**.
- **Rationale**: Accommodates natural speaker pauses and topical continuity in media, matching the `anki_split_gap_limit` configuration.

#### Scenario: 10s Gap Tolerance
- **WHEN** the term "falsch sind" is saved.
- **AND** Subtitle 2 starts 5.0 seconds after Subtitle 1 ends.
- **THEN** BOTH words SHALL remain highlighted as a unified phrase.

### Requirement: Local Timestamp Graceful Fallback
When evaluating a record at its original timestamp center, the highlighter SHALL prioritize Multi-Pivot grounding but MUST fallback to high-recall context matching (Word-Token Intersection) if coordinates are mismatched.
- **Rationale**: Prevents "highlight vanish" caused by minor coordinate drift (e.g., from punctuation handling changes) or subtitle index shifts on the original subtitle line.
- **Scope**: Applied only when the evaluation context sits at the record's original `start_time`.

### Requirement: Precision Neighborhood Verification (Token Intersection)
When Global Highlighting is active, the system SHALL perform a word-token intersection check against neighboring segments to ensure contextual validity.
- **Mechanism**: The engine SHALL scan neighboring segments (+/- `anki_neighbor_window`, default 5 lines).
- **Token Filtering**: It SHALL extract all word-character tokens of length >= 2, stripped of punctuation.
- **Match Threshold**: A highlight SHALL ONLY be rendered if at least one meaningful word from the neighborhood exists within the record's stored context (Word-Token Dictionary).
- **Match Integrity**: The matching process MUST use exact whole-word comparison (dictionary-based) to prevent substring collisions.
- **Self-Exclusion Rule**: The target term itself SHALL be explicitly excluded from the neighborhood check. A highlight requires at least one **additional** context word to be present in the neighborhood to establish validity.

### Requirement: Single-Word Global Recall Exemption
To maintain maximum recall for core vocabulary, the proximity grounding system SHALL implement a hybrid strictness model.
- **Single-Word Match**: Terms consisting of only one logical word SHALL be exempt from strict neighborhood verification when `anki_context_strict` is disabled.
- **Phrase Match**: Multi-word phrases SHALL remain subject to strict neighborhood verification to prevent coincidental matching across unrelated scenes.

### Requirement: Cloze-Aware Context Grounding
The context cleaning engine SHALL prioritize the preservation of textual content within Anki cloze deletions.
- **Behavior**: While standard ASS tags and square-bracket metadata (e.g. `[Musik]`) are stripped, content inside `{{c#::...}}` tags MUST be preserved as searchable tokens.
- **Rationale**: Ensures that clozed words remain effective anchors for neighborhood verification, preventing "vanishing highlights" for highly clozed cards.

#### Scenario: Contextual Anchor found
- **WHEN** `anki_global_highlight` is enabled.
- **AND** a textual match is found in a segment.
- **THEN** the engine scans +/- 5 neighbor lines.
- **IF** any word from those neighbors exists in the Anki context.
- **THEN** the highlight SHALL be rendered.

#### Scenario: Contextual Anchor NOT found
- **WHEN** no words from the neighborhood match the stored context.
- **AND** the word is NOT an exempted single-word.
- **THEN** the highlight SHALL NOT be rendered, preventing "common-word bleed" in unrelated scenes.

### Requirement: Deep Segment Peeking
The engine SHALL recursively traverse up to 5 adjacent subtitle segments to verify a phrase match.
- This ensures continuity for paragraphs that are heavily fragmented into single-word or short-phrase subtitles.

### Requirement: Adaptive Temporal Highlight Window
The engine SHALL calculate the fuzzy matching window dynamically based on the length of the saved term.
- Base window: `anki_local_fuzzy_window` (default 10s).
- Growth: +0.5 seconds for every word beyond the 10th word.

### Requirement: Performance Caching
The engine SHALL cache word lists and cleaned text for all highlight terms on first access to ensure rendering latency stays within acceptable OSD limits even with hundreds of active terms.

### Requirement: Self-Contextualization
The engine SHALL verify word neighbors against both the original `SentenceSource` (context) and the `WordSource` (term) itself.

### Requirement: Adaptive Punctuation Rendering
- **Single-Word Mode**: Punctuation marks SHALL remain uncolored to provide a clean study interface.
- **Phrase Continuity Mode**: Internal punctuation marks SHALL be colored to maintain visual flow.
- **Multi-Match Priority**: **Phrase Continuity Mode** SHALL take precedence.

### Requirement: Clean Boundary Capture
Leading and trailing punctuation/whitespace SHALL be stripped from clipboard and Anki exports. Internal punctuation SHALL be preserved.

### Requirement: Metadata-Tolerant Context Matching
The highlight engine SHALL ignore or skip metadata tags (e.g., `[musik]`) during context matching if `anki_strip_metadata` is set to `yes`.

### Requirement: High-Fidelity Range Reconstruction
The reconstruction engine MUST preserve the exact character sequence, including internal punctuation and original whitespace tokens, when a range of contiguous words is selected.
