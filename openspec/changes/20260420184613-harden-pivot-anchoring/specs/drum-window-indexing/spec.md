## MODIFIED Requirements

### Requirement: Marker-Injection Pivot Anchoring
The system SHALL anchor the focus pivot to a specific logical coordinate rather than a geometric midpoint to eliminate search drift in variable-font environments.
- **Constraint**: The context search engine MUST use the Multi-Pivot map to uniquely identify the exact word occurrence in the subtitle database.
- **Verification**: The search engine SHALL verify a candidate word by comparing its logical index in the segment against the `WordIndex` stored in the Multi-Pivot map.
- **Fallback**: If no Multi-Pivot map is present (legacy records), the system SHALL fallback to geometric proximity matching.

#### Scenario: Resolving Repeated Terms via Logical Mapping
- **GIVEN** a subtitle segment: "Ich gehe, du gehst, er geht, sie gehen."
- **AND** the word "gehe" (Word 2) was saved with index `0:2:1`.
- **WHEN** the user exports context for this record.
- **THEN** the search engine SHALL skip all other occurrences of "geh-" and precisely anchor to the second logical word.

#### Scenario: Geometric Fallback for Legacy Records
- **GIVEN** an Anki record without a Multi-Pivot grounding map.
- **WHEN** the user exports context.
- **THEN** the system SHALL calculate the geometric midpoint of the term occurrence and select the one closest to the record's original `pivot_pos`.
