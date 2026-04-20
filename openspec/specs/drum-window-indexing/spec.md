# drum-window-indexing Specification

## Purpose
Ensure 100% precise, scene-locked highlighting and context extraction by implementing a robust multi-coordinate grounding system that survives changes in subtitle layout or identical term repetition.

## Requirements

### Requirement: Logical Word Indexing (Token Atomization)
The system SHALL assign a unique 1-indexed logical position to every word-character token within a subtitle segment.
- **Non-Word Tokens**: Punctuation, symbols, and whitespace SHALL be tokenized and SHALL be assigned a unique, stable **fractional logical index** (e.g., `word_index - 1 + sub_offset`) to enable granular interaction.
- **ASS Tags**: Metadata blocks (e.g., `{\pos(x,y)}`) SHALL be atomized and stripped from the indexing sequence.
- **Square Brackets**: Content within `[]` SHALL NOT be atomized, allowing granular selection of internal words and punctuation.

#### Scenario: Word count in simple sentence
- **GIVEN** a subtitle segment: `Sie hören die Nachrichtensendung nur einmal.`
- **THEN** matching logical indices SHALL be:
  - `Sie`: 1
  - `hören`: 2
  - `die`: 3
  - `Nachrichtensendung`: 4
  - `nur`: 5
  - `einmal`: 6

#### Scenario: Punctuation Indexing
- **GIVEN** a subtitle segment: `Hallo, Welt!`
- **THEN** matching logical indices SHALL be:
  - `Hallo`: 1
  - `,`: 1.1
  - ` `: 1.2
  - `Welt`: 2
  - `!`: 2.1

### Requirement: Multi-Pivot Grounding Map
To eliminate "highlight bleed" on identical terms, the system SHALL generate a comprehensive coordinate map for every word in a selection.
- **Format**: `LineOffset:WordIndex:TermPos` (e.g., `0:4:1`).
- **Resilience**: Coordinates SHALL be treated as the primary anchor. However, for matches sitting at the record's original time, the system SHALL fallback to context-verified fuzzy matching if grounding is broken.

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
- **Segment Drift Tolerance**: The system SHALL allow a `+/- 1` subtitle segment drift when resolving origin lines to account for temporal epsilon boundaries (`+1ms`).

### Requirement: Logical Hit-Test Snapping
The hit-testing engine SHALL implement logical token snapping for all mouse interactions.
- **Visual-to-Logical Mapping**: Clicks or drags landing on non-word tokens (spaces, punctuation) SHALL be identified by their unique fractional logical index.
- **Margin Snap**: Mouse coordinates outside the active text block (line gaps or margins) SHALL be clamped to the first/last logical word of the nearest visible subtitle line.
- **Precision**: The system SHALL use a 0.0001 epsilon for all logical index comparisons to ensure stability across floating-point coordinates.
