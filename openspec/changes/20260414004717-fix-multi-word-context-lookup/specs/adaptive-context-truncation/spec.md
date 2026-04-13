## ADDED Requirements

### Requirement: Non-Contiguous Term Context Anchor
When the composed term cannot be found verbatim in the context block (because it is a non-contiguous selection where words between the picks were skipped), the context extraction system SHALL fall back to anchoring the sentence boundary search on the **first word** of the composed term.

#### Scenario: Non-contiguous term verbatim search fails
- **WHEN** `extract_anki_context` is called with a composed term that does not appear as a verbatim substring of the context block (e.g. term is `"ist die Anwohner"` but text contains `"ist für die Anwohner"`)
- **THEN** the system SHALL locate the first whitespace-delimited word of the term in the context block
- **AND** use that position as the anchor for the backward/forward sentence boundary search
- **AND** return the sentence surrounding that anchor position

#### Scenario: First word not found in context (degenerate)
- **WHEN** even the first word of the composed term cannot be located in the context block
- **THEN** the system SHALL fall through to the existing behavior (return the full context blob), unchanged from before this requirement
