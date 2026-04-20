## ADDED Requirements

### Requirement: Multi-Pivot Coordinate Grounding
The system SHALL identify and store unique logical coordinates for every word in a selection to ensure absolute scene-locking regardless of identical terms in the context.

#### Scenario: Exporting Multi-Word Coordinates
- **WHEN** a user exports a selection
- **THEN** the system SHALL generate a coordinate string in the format `LineOffset:WordIndex:TermPos` for every word.
- **AND** this string SHALL be persisted in the `SentenceSourceIndex` field (or equivalent).

### Requirement: Index-Bounded Highlight Verification
The highlight engine SHALL use the multi-pivot coordinate string to perform strict existence checks during render.

#### Scenario: Grounded Highlighting
- **WHEN** `anki_global_highlight` is disabled
- **THEN** the engine SHALL only highlight tokens whose document position matches the `LineOffset` and `WordIndex` stored in the record.
- **AND** it SHALL bypass fuzzy context healing for records containing valid coordinate metadata.
