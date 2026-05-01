## ADDED Requirements

### Requirement: Verbatim-Aware Content Validation
The export pipeline SHALL validate the integrity of the selected term while respecting verbatim markers and whitespace. 
- A selection SHALL be considered valid for processing if it contains at least one non-whitespace character after stripping ASS tags `{...}`.
- Semantic brackets `[]` and other punctuation SHALL be counted as valid content characters.

#### Scenario: Validating Bracket-Only Selection
- **GIVEN** a user selects exactly `[...]`.
- **WHEN** the export logic validates the term.
- **THEN** it SHALL be considered a valid term for export (not empty).
- **AND** it SHALL NOT be discarded by the "Minimum Content" safety guard.
