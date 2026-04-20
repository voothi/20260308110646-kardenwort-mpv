## ADDED Requirements

### Requirement: Multi-Pivot Grounding Map
The system SHALL replace single-integer logical indexing with a comprehensive coordinate string for every word in a mining record.
- **Format**: `LineOffset:WordIndex:TermPos` (e.g., `0:4:1`).
- **Rationale**: Ensures 100% unique scene-locking for identical terms by storing exact document offsets instead of geometric line centers.

### Requirement: Marker-Injection Pivot Anchoring
The system SHALL anchor the focus pivot to a specific logical coordinate coordinate to eliminate search drift in variable-font environments.

### Requirement: Temporal Epsilon Guard
Anki export timestamps SHALL include a mandatory temporal offset to ensure reliable window positioning.
- **Offset**: `+0.001s` (1ms).
- **Rule**: The export timestamp MUST be `line.start_time + 0.001`.
