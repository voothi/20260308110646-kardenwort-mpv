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

### Requirement: Non-Contiguous Term Context Anchor
When the composed term cannot be found verbatim in the context block (due to non-contiguous selection or cross-line boundaries), the context extraction system SHALL find the best occurrence of every word in the term closest to the center and anchor the sentence boundary search on the **full span** of those matches.

#### Scenario: Non-contiguous term spanning sentence boundaries
- **WHEN** `extract_anki_context` is called with a term like `"und Ende"` where "und" is in the first sentence and "Ende" is in the second
- **THEN** the system SHALL calculate the distance of all occurrences of "und" and "Ende" to the center of the context window
- **AND** determine the span (min-start to max-end) that covers the best occurrences of both words
- **AND** use that span as the anchor for sentence boundary detection
- **AND** return all involved sentences (from the start of the "und" sentence to the end of the "Ende" sentence) correctly.
