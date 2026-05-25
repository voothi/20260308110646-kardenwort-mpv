## MODIFIED Requirements

### Requirement: Sentence Scoping via Punctuation Terminators
The sentence extraction phase of `extract_anki_context` SHALL locate the sentence containing the selection by scanning **backward** from `start_pos` and **forward** from `end_pos` for the nearest real sentence terminator (`.`, `!`, `?`), where "real" means **not** classified as an abbreviation by the shared `is_abbreviation` helper (see `subtitle-aware-sentence-extraction`). The scan SHALL traverse `\0` subtitle-line sentinels as if they were whitespace — sentinels are not boundaries. When no real terminator is found on either side, the entire joined context block SHALL be used as the sentence (see `subtitle-aware-sentence-extraction` → No-Terminator Fallback).

#### Scenario: Sentence scoping with terminators on both sides
- **WHEN** `extract_anki_context` receives a context string `"...Winterstiefel raus.\0Es kommt zu kräftigen Niederschlägen,\0die verbreitet als Schnee liegen\0bleiben. Autofahrer..."` and `start_pos` / `end_pos` mark the word `"verbreitet"`
- **THEN** the backward scan SHALL stop at `"raus."` and place `sent_start` immediately after that period
- **AND** the forward scan SHALL stop at `"bleiben."` and place `sent_end` immediately after that period (inclusive of the period)
- **AND** the returned primary sentence SHALL be `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."` (NUL replaced by space)

#### Scenario: Backward scan skips abbreviations
- **WHEN** the context string contains `"Es liegt ca. 97 km von Plattling"` and the selection anchors to `"97"`
- **THEN** the backward scan SHALL detect that `"ca."` is an abbreviation
- **AND** SHALL continue scanning past it
- **AND** the returned sentence SHALL include `"Es liegt ca. 97 km von Plattling"` (or extend further back if no other terminator is found within the context block)

#### Scenario: Forward scan includes the terminating punctuation
- **WHEN** the forward scan reaches `[.!?]` followed by whitespace, NUL, or end-of-string
- **AND** the preceding token is not classified as an abbreviation
- **THEN** the terminator character SHALL be included as the last character of the returned sentence

#### Scenario: No terminator found in either direction
- **WHEN** the joined context block contains no `.`, `!`, or `?` whose preceding token is not an abbreviation
- **THEN** the entire joined context block SHALL be returned as the primary sentence (with `\0` replaced by space)
- **AND** word-count truncation in the subsequent step SHALL still apply

### Requirement: Adaptive Word-Count Truncation
The context extraction system SHALL dynamically adjust the word-count truncation window based on the length of the selected term.

#### Scenario: Exporting a long term
- **WHEN** the selected term length (in words) plus a standard buffer exceeds the default `anki_context_max_words`
- **THEN** the system increases the effective truncation limit for that specific export to ensure surrounding context (at least 10 words if sentences allow) is preserved.

### Requirement: Increased Default Context Buffer
The system SHALL default to a higher word-count limit to accommodate complex sentence structures.

#### Scenario: Default export behavior
- **WHEN** an export is triggered without custom overrides
- **THEN** the system applies a default limit of 40 words (increased from 20).

### Requirement: Non-Contiguous Term Context Anchor (Sequential Forward Search)
When the composed term cannot be found verbatim in the context block (due to non-contiguous selection or cross-line boundaries), the context extraction system SHALL find the occurrences of each word in the term in their natural document order.

#### Scenario: Non-contiguous term spanning sentence boundaries
- **WHEN** `extract_anki_context` is called with a term containing multiple segments (e.g. `"she's ... six ... four"`)
- **THEN** the system SHALL anchor the search using the first word closest to the pivot center
- **AND** search for all subsequent words strictly forward from the previous match's end position
- **AND** use the absolute character offsets of the first and last matches (relative to the source line) to map the span into word indices.

### Requirement: Precision Offset Mapping
The system SHALL ensure that character-relative spans are mapped to word indices by accounting for leading character stripping during sentence cleaning.

#### Scenario: Mapping selection to word indices
- **WHEN** a sentence is stripped of leading whitespace or punctuation (e.g. `"  Wait, how..."` becomes `"Wait, how..."`)
- **THEN** the system SHALL calculate the actual start offset of the cleaned string within the source line
- **AND** derive word indices (`first_idx`, `last_idx`) using relative character offsets (`s_rel`, `e_rel`) based on this true origin.

### Requirement: Adaptive Span Padding for Wide Selections
When the highlighted span itself is wider than the allowed word limit, the system SHALL fallback to a tight-crop representation of the span with natural padding.

#### Scenario: Exporting a wide selection
- **WHEN** the detected word span between the first and last selected words is $\ge$ `anki_context_max_words`
- **THEN** the system SHALL return only the words within that span plus a small fixed padding (default `anki_context_span_pad = 3`) on each side
- **AND** clamp this padded range to the sentence boundaries.

## REMOVED Requirements

### Requirement: Sentence Scoping via Subtitle Boundaries
**Reason**: Used `\0` subtitle-line sentinels as the sentence boundary, which truncated `SentenceSource` to a single subtitle line even when the real grammatical sentence spanned 2-3 lines. This caused the regression observed in `20260412001656-hoeren-b2-telc-uebungstest.tsv` (e.g. `"die verbreitet als Schnee liegen"` instead of `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."`).

**Migration**: Replaced by `Sentence Scoping via Punctuation Terminators`. The joined context block still uses `\0` sentinels in its byte representation, but the scoping scan now traverses them; sentinels are consulted only by the no-terminator fallback path. No code outside `extract_anki_context` is affected.
