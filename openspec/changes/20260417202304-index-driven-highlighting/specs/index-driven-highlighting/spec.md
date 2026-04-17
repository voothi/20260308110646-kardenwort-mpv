## ADDED Requirements

### Requirement: Rich Tokenization and Caching
The system SHALL parse raw subtitle strings into an array of discrete token objects exactly once upon loading, caching the result to eliminate redundant parsing during the render loop.

#### Scenario: Tokenizing a subtitle with punctuation
- **WHEN** the text "Hallo, Welt!" is parsed
- **THEN** the cached array SHALL contain distinct objects for "Hallo", ",", " ", "Welt", and "!".
- **AND** only "Hallo" and "Welt" SHALL be assigned sequential `logical_idx` values.

### Requirement: Deterministic Index Matching
The highlighting engine SHALL determine text overlap by evaluating sequences of logical indices rather than performing raw string or substring searches.

#### Scenario: Highlighting a contiguous phrase
- **WHEN** the multi-word term "guten Morgen" is evaluated against a subtitle token stream
- **THEN** the engine SHALL confirm a match ONLY if the word "guten" exists at `logical_idx = x` and "Morgen" exists at `logical_idx = x + 1`.

#### Scenario: Applying ASS tags via Visual Index
- **WHEN** the rendering loop constructs the final OSD string
- **THEN** it SHALL apply the appropriate ASS highlight tag directly to the `text` property of the specific `visual_idx` token, bypassing the need for regex-based punctuation isolation.
