# subtitle-aware-sentence-extraction Specification

## Purpose
Ensure that sentence boundaries for Anki context extraction are derived from real sentence punctuation, not subtitle line edges, while preserving abbreviation-heavy German text.
## Requirements
### Requirement: Punctuation-Anchored Sentence Scoping
The context extraction system SHALL derive sentence boundaries from the nearest real sentence terminator on either side of the selection, scanning across subtitle-line NUL sentinels (`\0`). The set of terminator characters SHALL be configurable via `anki_sentence_terminators` (default: `".!?"`). The system SHALL NOT use subtitle-line edges as sentence boundaries when terminators are available. Abbreviations matched by heuristic, by `anki_abbrev_list`, or by spaced-initialism handling SHALL NOT count as terminators. Sentence scoping SHALL remain the base behavior before any optional word-padding extension is applied.

#### Scenario: Sentence spanning multiple subtitle lines
- **WHEN** subtitle N reads `"Es kommt zu kräftigen Niederschlägen,"`
- **AND** subtitle N+1 reads `"die verbreitet als Schnee liegen"`
- **AND** subtitle N+2 reads `"bleiben. Autofahrer sollten besonders"`
- **AND** the user selects the word `"verbreitet"` from subtitle N+1
- **THEN** the system SHALL return `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."` as the primary sentence
- **AND** the system SHALL NOT truncate the result to a single subtitle line

#### Scenario: Selection spanning multiple sentences
- **WHEN** the user selects a non-contiguous phrase whose first word lies in sentence A and last word lies in sentence B
- **THEN** the system SHALL return the full text from the terminator preceding sentence A's start through the terminator ending sentence B, inclusive
- **AND** the system SHALL include every intermediate sentence in its entirety

#### Scenario: Backward scan stops at the nearest real terminator
- **WHEN** the joined context contains `"Winterstiefel raus.\0Es kommt zu kräftigen Niederschlägen,\0die verbreitet als Schnee liegen"` and the selection anchors to `"verbreitet"`
- **THEN** the backward scan SHALL stop at `"raus."`
- **AND** the returned sentence SHALL begin with `"Es kommt zu kräftigen Niederschlägen,"`, not with `"die verbreitet ..."`

#### Scenario: Forward scan includes the terminating punctuation
- **WHEN** the forward scan finds `.`, `!`, or `?` after the selection
- **THEN** the returned sentence SHALL include that terminator character

#### Scenario: Word padding keeps sentence scan as base
- **WHEN** sentence-based extraction uses `anki_context_words_before` or `anki_context_words_after`
- **AND** the joined context contains a real sentence terminator before the selected span
- **THEN** the backward sentence scan SHALL use the same abbreviation-aware terminator rules as `sentence` mode
- **AND** any configured word padding SHALL be applied only after the base sentence span has been found

### Requirement: No-Terminator Fallback to Full Joined Context
When neither the backward nor the forward sentence-terminator scan finds a real terminator within the joined context block, the system SHALL return the entire joined context with `\0` sentinels replaced by spaces. Subsequent word-count truncation (`anki_context_max_words`) SHALL still apply.

#### Scenario: Unpunctuated auto-subtitle block
- **WHEN** the joined context is `"so the next morning I went\0to the store and bought\0three apples and a pear"`
- **AND** the selection anchors to `"apples"`
- **THEN** the returned sentence SHALL be `"so the next morning I went to the store and bought three apples and a pear"`
- **AND** the system SHALL NOT return only `"three apples and a pear"`

#### Scenario: Asymmetric terminator availability
- **WHEN** the backward scan finds a terminator but the forward scan does not
- **THEN** the returned sentence SHALL begin after the backward terminator and extend to the end of the joined context block

### Requirement: Abbreviation-Aware Sentence Boundary Detection
The sentence-scoping scan and the word-level `is_sentence_boundary` check SHALL share abbreviation handling. A token SHALL be classified as an abbreviation when it matches the smart heuristic, appears in `Options.anki_abbrev_list` as a case-insensitive exact token, or participates in a spaced initialism such as `"z. B."`.

#### Scenario: Heuristic catches short German abbreviation
- **WHEN** the scan encounters `"ca."` immediately before a candidate terminator position
- **THEN** the scan SHALL continue past this `.`, not treat it as a sentence end

#### Scenario: Allowlist catches token outside the heuristic
- **WHEN** `anki_abbrev_list` contains `"etc."` and the scan encounters `"etc."`
- **THEN** the scan SHALL skip this `.`

#### Scenario: Spaced initialism is not split
- **WHEN** the scan encounters `"z. B. Globus"` inside a sentence
- **THEN** neither the period after `"z"` nor the period after `"B"` SHALL truncate the returned sentence

#### Scenario: Genuine sentence end is detected
- **WHEN** the scan encounters `"raus."` and `"raus."` is not matched by the heuristic and not in `anki_abbrev_list`
- **THEN** the scan SHALL treat this `.` as a sentence terminator

### Requirement: Configurable Abbreviation Allowlist
The system SHALL expose `anki_abbrev_list` as a script option. Its value SHALL be a space-separated list of abbreviation tokens. The default value SHALL include common German abbreviations.

#### Scenario: Default value covers common German abbreviations
- **WHEN** the user does NOT set `kardenwort-anki_abbrev_list` in `mpv.conf`
- **THEN** the effective list SHALL include at minimum `z.B.`, `bzw.`, `usw.`, `ca.`, `d.h.`, `u.a.`, `etc.`, `vgl.`, `ggf.`, `bspw.`

#### Scenario: User extends the allowlist
- **WHEN** `mpv.conf` contains `script-opts=kardenwort-anki_abbrev_list=z.B. bzw. usw. ca. Inc. Prof.`
- **AND** the scan encounters `"Prof."` in subtitle text
- **THEN** `"Prof."` SHALL be treated as an abbreviation

### Requirement: Configurable Sentence Terminators
The system SHALL expose `anki_sentence_terminators` as a script option whose value is a string of individual terminator characters. Each character in the string is treated as an independent sentence terminator. The default value SHALL be `".!?"`.

#### Scenario: Default terminators
- **WHEN** the user does NOT set `kardenwort-anki_sentence_terminators` in `mpv.conf`
- **THEN** the scan SHALL treat `.`, `!`, and `?` as sentence terminators

#### Scenario: User adds terminator characters
- **WHEN** `mpv.conf` contains `script-opts=kardenwort-anki_sentence_terminators=.!?;`
- **THEN** `;` SHALL be treated as an additional sentence terminator during the scan
- **AND** existing `.!?` behavior SHALL be preserved

#### Scenario: User narrows terminators
- **WHEN** `mpv.conf` contains `script-opts=kardenwort-anki_sentence_terminators=.`
- **THEN** only `.` SHALL end a sentence

#### Scenario: Empty or missing value falls back to default
- **WHEN** `anki_sentence_terminators` is set to an empty string
- **THEN** the system SHALL behave as if the default `".!?"` was set

### Requirement: NUL Sanitization in Subtitle Loader
The subtitle parser SHALL strip any NUL bytes from subtitle text before storing, to prevent sentinel collisions in the joined context block.

#### Scenario: Subtitle text with embedded NUL
- **WHEN** a subtitle file contains a NUL byte in its text content
- **THEN** the loader SHALL remove that byte before storing the text
- **AND** the rest of the subtitle text SHALL be preserved intact

### Requirement: Literal Context Extraction
The `SentenceSource` context field in exported Anki cards SHALL preserve the exact punctuation and spacing of the source subtitle by extracting substrings directly from the original text, rather than re-tokenizing and joining word lists.

#### Scenario: Complex punctuation in context
- **WHEN** a subtitle contains `Paketsortierung. [UMGEBUNG]`
- **THEN** the context extraction SHALL return the substring exactly as it appears in the source, including the space between the period and the bracket

#### Scenario: Multi-line sentence preserves original spacing
- **WHEN** the sentence-scoping scan returns content that originally spanned three subtitle lines joined by `\0`
- **THEN** the `\0` sentinels SHALL be replaced by single spaces in the returned sentence
- **AND** no other whitespace normalization SHALL be applied

