# export-engine-hardening Specification

## Purpose
TBD - created by archiving change 20260421231238-fix-export-freeze-and-harden-stability. Update Purpose after archive.
## Requirements
### Requirement: Search Loop Safety Guards
All string search engines (context extraction, fuzzy matching, and pivot grounding) MUST implement mandatory forward progress guards. 
- **Pattern Check**: The system SHALL NOT initiate a `string.find` or `gmatch` loop if the search pattern is an empty string.
- **Pointer Progress**: Every iteration of a search loop MUST advance the `search_from` pointer by at least 1 character index, regardless of the match result.
- **Safety Limit**: Infinite loop detection (safety counter) SHALL be active for all non-deterministic loops.

#### Scenario: Empty string search attempt
- **WHEN** a function attempts to find occurrences of `""` (empty string) in a text block.
- **THEN** the search SHALL return no results immediately.
- **AND** the system SHALL NOT hang or enter a loop.

### Requirement: Verbatim-Aware Content Validation
The export pipeline SHALL validate the integrity of the selected term while respecting verbatim markers and whitespace. 
- A selection SHALL be considered valid for processing if it contains at least one non-whitespace character after stripping ASS tags `{...}`.
- Semantic brackets `[]` and other punctuation SHALL be counted as valid content characters.

#### Scenario: Validating Bracket-Only Selection
- **GIVEN** a user selects exactly `[...]`.
- **WHEN** the export logic validates the term.
- **THEN** it SHALL be considered a valid term for export (not empty).
- **AND** it SHALL NOT be discarded by the "Minimum Content" safety guard.

#### Scenario: Clicking on whitespace between words
- **WHEN** the user middle-clicks in a gap between words that contains no selectable text.
- **THEN** the export logic SHALL detect the empty term result.
- **AND** the export SHALL be aborted before calling the context extractor.

