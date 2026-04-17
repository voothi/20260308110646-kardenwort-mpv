## ADDED Requirements

### Requirement: Cross-Segment Neighbor Integrity
The system SHALL ensure that word neighbor lookups (for context matching) remain accurate across subtitle segment boundaries when utilizing logical indices.

#### Scenario: Neighbor matching at segment boundary
- **GIVEN** a word at the end of Subtitle A and its following neighbor is at the start of Subtitle B
- **WHEN** the neighbor lookup is performed across the segment boundary
- **THEN** THE system SHALL adjust the target logical index to correctly reference the corresponding word in the adjacent segment (e.g., word 1 of Subtitle B).

### Requirement: Deterministic Color Mapping (Split vs Contiguous)
The system SHALL maintain a strict visual distinction between contiguous word sequences and non-contiguous (split) word sequences in highlighting.

#### Scenario: Long contiguous phrase highlighting
- **GIVEN** a contiguous phrase of any length (e.g. "Der schnelle braune Fuchs")
- **WHEN** this phrase is matched as a highlight from Anki
- **THEN** it SHALL be rendered using the Contiguous highlight color (Orange) regardless of word count.
- **AND** the Split highlight color (Purple) SHALL be reserved exclusively for matches where words are separated in the source text.

### Requirement: Unified Token-Driven Export
Anki export and selection logic SHALL utilize the same token-driven architecture as the rendering engine.

#### Scenario: Selection Anchor Consistency
- **WHEN** a selection is made in the Drum Window
- **THEN** the logical index and token data captured for export SHALL be identical to the data used for rendering and highlight calculation.
- **AND** the system SHALL NOT fallback to raw string-based processing for selection reconstruction.
