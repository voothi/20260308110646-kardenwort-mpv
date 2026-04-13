## ADDED Requirements

### Requirement: Non-Contiguous Term Context Anchor
When the composed term cannot be found verbatim in the context block (due to non-contiguous selection or cross-line boundaries), the context extraction system SHALL find all occurrences of every word in the term and anchor the sentence boundary search on the occurrence whose midpoint is **closest to the center of the context blob**.

#### Scenario: Non-contiguous term with common words
- **WHEN** `extract_anki_context` is called with a term like `"und Ende"` where the verbatim search fails
- **THEN** the system SHALL calculate the distance of all occurrences of "und" and "Ende" to the center of the context window
- **AND** use the position of the occurrence closest to the center as the anchor for sentence boundary detection
- **AND** return the sentence containing that specific occurrence, ensuring that common words earlier in the padding do not pull the context to the wrong sentence.
