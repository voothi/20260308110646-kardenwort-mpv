## ADDED Requirements

### Requirement: Context Scope Mode Selection
The context extraction system SHALL expose `anki_context_scope_mode` to select how Anki context boundaries are calculated. Supported values SHALL be `sentence`, `sentence-word-padding`, `word-window`, and `auto`. The default SHALL be `sentence` to preserve existing behavior.

#### Scenario: Default mode preserves current behavior
- **WHEN** the user does not configure `anki_context_scope_mode`
- **THEN** the system SHALL behave as if `anki_context_scope_mode` is `sentence`
- **AND** the configured word-padding values SHALL NOT expand the exported context

#### Scenario: Invalid mode falls back safely
- **WHEN** `anki_context_scope_mode` contains an unsupported value
- **THEN** the system SHALL behave as if `anki_context_scope_mode` is `sentence`

#### Scenario: Auto mode chooses a safe fallback
- **WHEN** `anki_context_scope_mode` is `auto`
- **AND** the system cannot reliably determine that the source subtitles are auto-generated or sentence-unreliable
- **THEN** the system SHALL use `sentence` behavior

### Requirement: Configurable Before And After Word Padding
The context extraction system SHALL expose `anki_context_words_before` and `anki_context_words_after` as non-negative integer settings. These settings SHALL define how many logical words may be added before and after the selected span when the active context mode uses word padding.

#### Scenario: Padding settings are applied independently
- **WHEN** `anki_context_scope_mode` is `word-window`
- **AND** `anki_context_words_before` is `3`
- **AND** `anki_context_words_after` is `1`
- **AND** the selected term is `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`
- **AND** the joined context is `VAZ Fit for the job ## Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH ### Ein Unternehmen der Koder-Gruppe`
- **THEN** the exported context SHALL be `for the job ## Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH ### Ein`

#### Scenario: Padding clamps to available source text
- **WHEN** the requested before or after word count exceeds the available words in the joined context
- **THEN** the extracted context SHALL clamp to the beginning or end of the joined context
- **AND** the system SHALL NOT throw an error

#### Scenario: Negative padding values are normalized
- **WHEN** `anki_context_words_before` or `anki_context_words_after` is less than `0`
- **THEN** the system SHALL treat the negative value as `0`

### Requirement: Sentence Word Padding Mode
When `anki_context_scope_mode` is `sentence-word-padding`, the system SHALL first calculate the base context using the same abbreviation-aware sentence-boundary logic as `sentence` mode, then expand the resulting literal source span by the configured number of logical words before and after that base span.

#### Scenario: Manual subtitle sentence is expanded by words
- **WHEN** `anki_context_scope_mode` is `sentence-word-padding`
- **AND** `anki_context_words_before` is `3`
- **AND** `anki_context_words_after` is `1`
- **AND** the base sentence span begins at `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`
- **AND** the joined context is `VAZ Fit for the job ## Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH ### Ein Unternehmen der Koder-Gruppe`
- **THEN** the exported context SHALL include the preceding words `for the job`
- **AND** the exported context SHALL include the following word `Ein`
- **AND** structural markers such as `##` and `###` inside the selected substring SHALL be preserved

#### Scenario: Disabled padding remains sentence-only
- **WHEN** `anki_context_scope_mode` is `sentence-word-padding`
- **AND** `anki_context_words_before` is `0`
- **AND** `anki_context_words_after` is `0`
- **THEN** the exported context SHALL match the sentence-scoped result before word padding

### Requirement: Word Window Mode
When `anki_context_scope_mode` is `word-window`, the system SHALL bypass sentence-terminator scanning and calculate the exported context directly from the selected span plus `anki_context_words_before` and `anki_context_words_after` logical words in the joined context.

#### Scenario: Word window bypasses punctuation scanning
- **WHEN** `anki_context_scope_mode` is `word-window`
- **AND** the joined context contains periods inside abbreviations such as `i. d. Opf. GmbH`
- **THEN** the system SHALL NOT use `.`, `!`, or `?` to decide the context boundaries
- **AND** the context boundaries SHALL be based on logical word positions relative to the selected span

#### Scenario: Auto subtitle word window
- **WHEN** `anki_context_scope_mode` is `auto`
- **AND** the source subtitles are identified as auto-generated or sentence-unreliable
- **THEN** the system SHALL use `word-window` behavior
