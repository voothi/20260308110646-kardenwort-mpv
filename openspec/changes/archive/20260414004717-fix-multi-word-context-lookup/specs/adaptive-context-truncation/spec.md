## ADDED Requirements

### Requirement: Non-Contiguous Term Context Anchor
When the composed term cannot be found verbatim in the context block (due to non-contiguous selection or cross-line boundaries), the context extraction system SHALL find the best occurrence of every word in the term closest to the center and anchor the sentence boundary search on the **full span** of those matches.

#### Scenario: Non-contiguous term spanning sentence boundaries
- **WHEN** `extract_anki_context` is called with a term like `"und Ende"` where "und" is in the first sentence and "Ende" is in the second
- **THEN** the system SHALL calculate the distance of all occurrences of "und" and "Ende" to the center of the context window
- **AND** determine the span (min-start to max-end) that covers the best occurrences of both words
- **AND** use that span as the anchor for sentence boundary detection
- **AND** return all involved sentences (from the start of the "und" sentence to the end of the "Ende" sentence) correctly.
