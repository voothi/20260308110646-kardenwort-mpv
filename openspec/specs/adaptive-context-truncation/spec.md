# adaptive-context-truncation Specification

## Purpose
TBD - created by archiving change 20260413213102-fix-anki-context-truncation. Update Purpose after archive.
## Requirements
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

### Requirement: Sentence Scoping via Subtitle Boundaries
The sentence extraction phase of `extract_anki_context` SHALL use NUL sentinel characters (`\0`) embedded in the context string to locate the subtitle line containing the selection, and SHALL NOT scan for period characters to determine sentence start or end.

#### Scenario: Sentence scoping from sentinel-delimited context
- **WHEN** `extract_anki_context` receives a context string with `\0`-delimited subtitle segments and a character offset (`start_pos`) within that string
- **THEN** the system SHALL search backwards from `start_pos` for the nearest `\0` to find the start of the containing subtitle
- **AND** search forwards from `end_pos` for the nearest `\0` (or string end) to find the end of the containing subtitle
- **AND** use the text between those two positions as the primary sentence for word-count evaluation

#### Scenario: Backwards scan no longer uses period characters
- **WHEN** the context string contains `"Es liegt ca.\097 km"` (NUL between subtitle lines) and the selection anchors to `"97"`
- **THEN** the backwards scan SHALL stop at the `\0` sentinel, not at `"ca."`
- **AND** the returned primary sentence SHALL be `"97 km"` (the subtitle containing the selection), not a fragment starting after `"ca."`
