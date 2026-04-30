## ADDED Requirements

### Requirement: Character-Offset Precision Anchoring
The anchoring system SHALL support optional character-level offsets within the coordinate index string to enable precision capture of non-contiguous fragments.

#### Scenario: Split Phrase Export
- **WHEN** a user selects a non-contiguous phrase where boundaries fall within a word or adjacent to specific punctuation
- **THEN** the system SHALL store character-level offsets in the `item_index` (e.g., `Line:Word:Char`) to ensure verbatim reconstruction.

#### Scenario: Backward compatibility with existing indices
- **WHEN** the system encounters an existing `item_index` without a character-level offset (e.g., `0:3`)
- **THEN** the system SHALL treat the offset as 0 (start of word) and continue normal processing.
- **AND** no existing TSV records SHALL be invalidated.
