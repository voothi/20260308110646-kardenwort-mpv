# drum-window-indexing Specification

## Purpose
Ensure 100% precise, scene-locked highlighting and context extraction by implementing a robust multi-coordinate grounding system that survives changes in subtitle layout or identical term repetition.

## Requirements

### Requirement: Logical Word Indexing (Token Atomization)
The system SHALL assign a unique 1-indexed logical position to every word-character token within a subtitle segment.
- **Non-Word Tokens**: Punctuation, symbols, and whitespace SHALL be tokenized but SHALL NOT increment the logical index.
- **ASS Tags**: Metadata blocks (e.g., `{\pos(x,y)}`) SHALL be atomized and stripped from the indexing sequence.

### Requirement: Multi-Pivot Grounding Map
To eliminate "highlight bleed" on identical terms, the system SHALL generate a comprehensive coordinate map for every word in a selection.
- **Format**: `LineOffset:WordIndex:TermPos` (e.g., `0:4:1`).
- **Resilience**: Coordinates SHALL be treated as the primary anchor. However, for matches sitting at the record's original time, the system SHALL fallback to context-verified fuzzy matching if grounding is broken, ensuring continuity for newly-added terms.

#### Scenario: Exporting a Multi-Word Coordinate Map
- **WHEN** a user exports a three-word selection spanning two lines.
- **THEN** the `SentenceSourceIndex` field in the TSV SHALL contain a comma-separated list of coordinates:
    - Example: `0:15:1,0:16:2,1:1:3` (Covers word 15 & 16 of current line, and word 1 of next line).

### Requirement: Marker-Injection Pivot Anchoring
The system SHALL anchor the focus pivot to a specific logical coordinate rather than a geometric midpoint to eliminate search drift in variable-font environments.
- **Constraint**: The context search engine MUST use the Multi-Pivot map to uniquely identify the exact word occurrence in the subtitle database.
- **Fallback**: If no Multi-Pivot map is present (legacy records), the system SHALL fallback to geometric proximity matching.

### Requirement: Temporal Epsilon Guard
Exports SHALL include a mandatory temporal offset to ensure the recorded timestamp sits reliably within the subtitle's active window.
- **Offset**: `+0.001s` (1ms).
- **Rule**: The Anki export timestamp SHALL be `primary_line.start_time + 0.001`.

### Requirement: Index-Bounded Highlight Verification
The highlight engine SHALL use the coordinate map to perform strict existence checks during render.
- **Grounded Highlighting**: When `anki_global_highlight` is disabled, the engine SHALL only highlight tokens whose logical position matches the stored mapping.
- **Fuzzy Bypass**: Records with valid Multi-Pivot metadata MUST bypass literal context healing loops in favor of coordinate-perfect matching.
