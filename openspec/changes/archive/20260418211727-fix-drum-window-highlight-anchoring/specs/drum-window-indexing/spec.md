# drum-window-indexing

## Purpose
This specification defines the logical word-level indexing system used in the Drum Window for precise selection, export, and highlight anchoring. It ensures that every word within a subtitle segment can be uniquely identified, preventing "highlight bleed" and maintaining 100% precision even when identical words appear in close proximity.

## ADDED Requirements

### Requirement: Logical Word Indexing
The system SHALL assign a unique 1-indexed logical position to every word-character token within a subtitle segment.

- **Non-Word Tokens**: Punctuation, symbols, and whitespace SHALL be tokenized but SHALL NOT increment the logical index.
- **ASS Tags**: Metadata blocks (e.g., `{\pos(x,y)}`) SHALL be completely ignored for indexing purposes.

#### Scenario: Word count in simple sentence
- **GIVEN** a subtitle segment: `Sie hören die Nachrichtensendung nur einmal.`
- **THEN** matching logical indices SHALL be:
  - `Sie`: 1
  - `hören`: 2
  - `die`: 3
  - `Nachrichtensendung`: 4
  - `nur`: 5
  - `einmal`: 6

#### Scenario: Metadata and Punctuation Skipping
- **GIVEN** a subtitle segment: `{\pos(10,20)}Hallo, Welt!`
- **THEN** matching logical indices SHALL be:
  - `Hallo`: 1
  - `, Welt`: `Hallo` remains 1, the space and comma skip, `Welt` becomes 2.

### Requirement: Pivot-Point Anchoring
During context extraction and search, the system SHALL calculate a character-offset "Pivot" based on the user's focus point to eliminate search drift.

- **Pivot Calculation**: For single-click exports, the pivot SHALL be the middle character index of the clicked word within the cleaned (tag-free) context block.
- **Pivot Proximity**: The context search engine SHALL identify all candidate occurrences of a term and select the one with the smallest absolute distance between its midpoint and the calculated Pivot.

#### Scenario: Resolving Ambiguous Words
- **GIVEN** a context block containing two sentences: `[S1] Sie hören die Nachricht. [S2] Entscheiden Sie, ob die Aussagen richtig sind.`
- **WHEN** a user clicks on `die` in [S1].
- **THEN** the system SHALL calculate a pivot within the [S1] range.
- **AND** the search engine SHALL select the first `die` because it is closer to the pivot than the `die` in [S2].

### Requirement: Index Persistence
The logical word index SHALL be persisted in the exported database record via the `SentenceSourceIndex` field.

#### Scenario: Exporting a selection record
- **WHEN** a user exports a word selection from the Drum Window.
- **THEN** the record exported to the TSV SHALL include:
  - **SentenceSource**: The text of the subtitle segment containing the selection.
  - **SentenceSourceIndex**: The 1-indexed logical position of the first word of the selection within that segment.
