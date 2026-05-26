## MODIFIED Requirements

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
When neither the backward nor the forward sentence-terminator scan finds a real terminator within the joined context block, the system SHALL return the entire joined context with `\0` sentinels replaced by spaces. Subsequent word-count truncation (`anki_context_max_words`) SHALL still apply. When optional auto-subtitle word-window fallback is active for the current extraction, the system SHALL bypass this no-terminator fallback and use word-window boundaries instead.

#### Scenario: Unpunctuated auto-subtitle block
- **WHEN** the joined context is `"so the next morning I went\0to the store and bought\0three apples and a pear"`
- **AND** the selection anchors to `"apples"`
- **THEN** the returned sentence SHALL be `"so the next morning I went to the store and bought three apples and a pear"`
- **AND** the system SHALL NOT return only `"three apples and a pear"`

#### Scenario: Asymmetric terminator availability
- **WHEN** the backward scan finds a terminator but the forward scan does not
- **THEN** the returned sentence SHALL begin after the backward terminator and extend to the end of the joined context block

#### Scenario: Auto fallback word window does not use no-terminator fallback
- **WHEN** `anki_context_auto_word_window` is `true`
- **AND** auto-subtitle fallback is active for the current extraction
- **AND** the joined context contains no sentence terminators
- **THEN** the exported context SHALL be bounded by `anki_context_words_before` and `anki_context_words_after`
- **AND** the system SHALL NOT first expand to the full joined context block
