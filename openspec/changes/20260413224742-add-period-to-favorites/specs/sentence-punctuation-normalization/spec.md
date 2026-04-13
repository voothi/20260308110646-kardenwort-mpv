## ADDED Requirements

### Requirement: Automatic Sentence Punctuation Recovery in source_word
The Anki export system SHALL preserve terminal punctuation (`.`, `!`, `?`) in the `source_word` field for sentence-level exports.

When the original subtitle text ends with terminal punctuation **and** the cleaned term starts with an uppercase letter, the system SHALL restore a period at the end of the term after the punctuation-stripping cleanup step.

#### Scenario: Preserving period in capitalized subtitle sentence
- **GIVEN** a subtitle segment that contains `Die Luftfahrtbranche befindet sich im Umbruch.`
- **WHEN** the user saves the entire subtitle line as a favorite
- **THEN** the `source_word` field SHALL contain `Die Luftfahrtbranche befindet sich im Umbruch.` (with the period).

#### Scenario: Preserving existing punctuation — no double-period
- **WHEN** the cleaned term already ends with terminal punctuation (`.`, `!`, or `?`)
- **THEN** the system SHALL NOT append an additional period.

#### Scenario: Ignoring lowercase fragments
- **WHEN** the cleaned term starts with a lowercase letter
- **THEN** the system SHALL NOT restore terminal punctuation, treating it as a phrase fragment.

#### Scenario: Multi-line subtitle period restoration
- **GIVEN** a subtitle split across two visual lines, e.g. `Die Luftfahrtbranche\nUmbruch.`
- **WHEN** the user exports the full subtitle
- **THEN** the `source_word` SHALL be `Die Luftfahrtbranche Umbruch.` with the period intact.

#### Scenario: Single capitalized word — no period
- **GIVEN** a subtitle segment containing only `Umbruch.`
- **WHEN** the user saves the word `Umbruch`
- **THEN** the `source_word` field SHALL contain `Umbruch` (without the period).

#### Scenario: Capitalized phrase in the middle of a sentence — no period (German nouns)
- **GIVEN** a subtitle segment `Sie haben dazu 30 Sekunden Zeit.`
- **WHEN** the user saves the phrase `Sekunden Zeit`
- **THEN** the `source_word` field SHALL contain `Sekunden Zeit` (no period added, as it did not start the sentence).
