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

### Requirement: Export Input Validation
The Anki export pipeline MUST validate the "cleaned" term after stripping ASS tags and whitespace.
- **Minimum Content**: A term SHALL only be processed for export if it contains at least one non-whitespace character after stripping.
- **Silent Drop**: If a selection consists only of tags, spaces, or formatting, the export request SHALL be silently ignored to prevent corrupted data entries and logic errors.

#### Scenario: Clicking on whitespace between words
- **WHEN** the user middle-clicks in a gap between words that contains no selectable text.
- **THEN** the export logic SHALL detect the empty term result.
- **AND** the export SHALL be aborted before calling the context extractor.

