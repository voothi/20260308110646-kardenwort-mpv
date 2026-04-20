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

### Requirement: Logical Word Indexing (Token Atomization)
The system SHALL assign a unique 1-indexed logical position to every word-character token within a subtitle segment.
- **Non-Word Tokens**: Punctuation, symbols, and whitespace SHALL be tokenized and SHALL increment the logical index in fractional steps (0.1) relative to the preceding word.
- **Epsilon Guard**: The comparison of logical indices SHALL use a `0.0001` epsilon buffer to ensure numerical stability.

#### Scenario: Fractional Indexing of Punctuation
- **GIVEN** a subtitle segment: "Hallo, Welt!"
- **THEN** matching logical indices SHALL be:
  - "Hallo": 1
  - ",": 1.1
  - " ": 1.2
  - "Welt": 2
  - "!": 2.1
