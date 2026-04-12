# subtitle-rendering Specification

## Purpose
TBD - created by archiving change 20260412184520-anki-highlighter. Update Purpose after archive.
## Requirements
### Requirement: Compound Intensity Rendering
The subtitle OSD formatting engine SHALL parse all active TSV highlight objects for the current context and apply depth-stacking BGR colors to the rendered words. 

#### Scenario: Rendering an overlapping highlight
- **WHEN** a subtitle sentence contains two highlighted words, but one of those words is also part of a larger, surrounding highlight quote
- **THEN** that specific word receives a progressively darker 'Rust' palette color (`depth_1` -> `depth_3`) compared to the un-overlapped highlighted word.

### Requirement: Whole-Word Matching Filter
The rendering engine SHALL use whole-word tokenization when calculating highlight depth to prevent accidental substring matches.

#### Scenario: Preventing partial word highlights
- **WHEN** the term `Aufgaben` is highlighted in the database
- **THEN** the stand-alone word `auf` in the subtitles SHALL NOT be highlighted, as it is a substring but not a whole-word match of the term.

### Requirement: Temporal Fuzzy Window
Local highlights SHALL be evaluated against a configurable temporal buffer (`anki_local_fuzzy_window`) to ensure multi-subtitle sentence highlights stack correctly.

#### Scenario: Stacking across subtitle boundaries
- **WHEN** a phrase highlight spans two subtitles (Edges)
- **THEN** both parts of the phrase are highlighted correctly as long as their timestamps fall within the fuzzy window (default 10s).

