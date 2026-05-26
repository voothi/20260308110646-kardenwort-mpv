# subtitle-aware-sentence-extraction Specification

## Purpose
Ensure sentence boundaries for Anki context extraction follow real punctuation and abbreviation-aware rules across subtitle lines.

## Requirements

### Requirement: Punctuation-Anchored Sentence Scoping
The context extraction system SHALL derive sentence boundaries from the nearest real sentence terminator on either side of the selection, scanning across subtitle-line NUL sentinels (`\0`). Terminators SHALL be configurable via `anki_sentence_terminators` (default `".!?"`).

#### Scenario: Sentence spanning multiple subtitle lines
- **WHEN** subtitle lines form one grammatical sentence across `\0` joins and the selection is in the middle line
- **THEN** the returned primary sentence SHALL include the full sentence across those lines.

#### Scenario: Forward scan includes terminator
- **WHEN** the forward scan finds `.`, `!`, or `?` that is not part of an abbreviation
- **THEN** the returned sentence SHALL include that terminating punctuation.

### Requirement: No-Terminator Fallback to Full Joined Context
When neither backward nor forward scans find a real terminator, the system SHALL return the entire joined context block (with `\0` replaced by spaces), and later truncation rules still apply.

#### Scenario: Unpunctuated auto-subtitle block
- **WHEN** the joined context has no valid terminators
- **THEN** the output sentence SHALL be the full joined block, not only the selected subtitle line.

### Requirement: Abbreviation-Aware Sentence Boundary Detection
Sentence-scoping scans and word-level boundary checks SHALL share one `is_abbreviation(token)` helper. A token is an abbreviation when it matches the heuristic pattern or appears in `anki_abbrev_list` (case-insensitive).

#### Scenario: Heuristic match
- **WHEN** the scan encounters `"ca."`
- **THEN** it SHALL be treated as an abbreviation, not as a sentence terminator.

#### Scenario: Allowlist match
- **WHEN** `anki_abbrev_list` contains `"Prof."` and the scan encounters `"Prof."`
- **THEN** it SHALL be treated as an abbreviation.

### Requirement: Configurable Abbreviation Allowlist
The system SHALL expose `anki_abbrev_list` as a comma-separated script option of tokens including trailing periods.

#### Scenario: Default common abbreviations
- **WHEN** user config does not override `kardenwort-anki_abbrev_list`
- **THEN** the default list SHALL include common German abbreviations such as `z.B.`, `bzw.`, `usw.`, `ca.`, `d.h.`, `u.a.`, `etc.`, `vgl.`, `ggf.`, `bspw.`.

### Requirement: Configurable Sentence Terminators
The system SHALL expose `anki_sentence_terminators` as a string of individual terminator characters (default `".!?"`). Empty value SHALL fall back to default.

#### Scenario: User extends terminators
- **WHEN** the option is set to `".!?;"`
- **THEN** `;` SHALL also act as a sentence terminator.

#### Scenario: User narrows terminators
- **WHEN** the option is set to `"."`
- **THEN** only `.` SHALL be treated as a terminator.

### Requirement: NUL Sanitization in Subtitle Loader
The subtitle parser SHALL strip any NUL bytes from subtitle text before storage to prevent sentinel collisions.

#### Scenario: Embedded NUL in subtitle text
- **WHEN** input subtitle text contains a NUL byte
- **THEN** the NUL byte SHALL be removed and remaining text preserved.

### Requirement: Literal Context Extraction
The exported `SentenceSource` SHALL preserve original punctuation and spacing by extracting directly from source text, not by re-tokenizing and rejoining words.

#### Scenario: Complex punctuation in context
- **WHEN** a subtitle contains `Paketsortierung. [UMGEBUNG]`
- **THEN** extraction SHALL preserve the exact punctuation and spacing.
