## ADDED Requirements

### Requirement: Adaptive Contiguity Detection
The export system SHALL detect if a multi-word selection is non-contiguous in the source subtitle and adjust the saved term accordingly.

#### Scenario: Contiguous selection save
- **WHEN** a user selection contains words with sequential `logical_idx` values (e.g. 1, 2, 3).
- **THEN** the system SHALL join them with a single space (e.g. "word1 word2 word3") for the `source_word` field.

#### Scenario: Split selection save
- **WHEN** a user selection contains words with a gap in their `logical_idx` values (e.g. 1, 4).
- **THEN** the system SHALL join them using an ellipsis surrounded by spaces (e.g. "word1 ... word4") for the `source_word` field.
