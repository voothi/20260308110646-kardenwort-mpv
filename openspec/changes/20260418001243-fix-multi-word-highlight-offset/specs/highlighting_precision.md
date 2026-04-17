## ADDED Requirements

### Requirement: Offset-Aware Phrase Indexing
The highlighter must correctly verify the logical index of every word in a multi-word phrase against the phrase's exported anchor index.

#### Scenario: Contiguous Phrase Highlighting
- **WHEN** a multi-word phrase "A B C" is exported with a `SentenceSourceIndex` referring to the position of "A"
- **THEN** words "B" and "C" must be validated as matches if their logical indices match their relative position from "A"
- **AND** they must be highlighted using the Primary Highlight color (Orange) rather than the Split Match color (Purple)
