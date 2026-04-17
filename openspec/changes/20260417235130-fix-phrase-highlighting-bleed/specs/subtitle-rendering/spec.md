## ADDED Requirements

### Requirement: Multi-Word Phrase Precision
The system SHALL ensure that when global highlighting is disabled, multi-word phrases are isolated to the specific subtitle record and logical index that triggered the highlight.

#### Scenario: Selection Isolation for Repeating Phrases
- **GIVEN** `lls-anki_global_highlight=no`
- **AND** a subtitle track contains multiple identical phrases (e.g., "41 bis 45") within 15 lines of each other
- **WHEN** the user selects one of these phrases in the Drum Window
- **THEN** ONLY the selected phrase SHALL be highlighted.
- **AND** identical phrases in neighboring lines SHALL NOT be highlighted.
