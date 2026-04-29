## ADDED Requirements

### Requirement: Character-Offset Precision Anchoring
The anchoring system SHALL support optional character-level offsets within the coordinate index string to enable precision capture of non-contiguous fragments.

#### Scenario: Split Phrase Export
- **WHEN** A user selects a non-contiguous phrase where boundaries fall within a word or adjacent to specific punctuation.
- **THEN** The system SHALL store character-level offsets in the `item_index` (e.g., `Line:Word:Char`) to ensure verbatim reconstruction.
