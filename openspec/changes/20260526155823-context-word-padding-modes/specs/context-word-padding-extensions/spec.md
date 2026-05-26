## ADDED Requirements

### Requirement: Sentence Scope As Primary Behavior
The context extraction system SHALL keep sentence-based context extraction as the primary behavior. `anki_context_scope_mode` SHALL default to `sentence`, and all extension settings in this capability SHALL augment that baseline behavior instead of replacing it for manual subtitles.

#### Scenario: Default mode preserves current behavior
- **WHEN** the user does not configure `anki_context_scope_mode`
- **THEN** the system SHALL behave as if `anki_context_scope_mode` is `sentence`
- **AND** the exported context SHALL use abbreviation-aware sentence boundaries as today

#### Scenario: Invalid mode falls back safely
- **WHEN** `anki_context_scope_mode` contains an unsupported value
- **THEN** the system SHALL behave as if `anki_context_scope_mode` is `sentence`

### Requirement: Configurable Before And After Word Padding
The context extraction system SHALL expose `anki_context_words_before` and `anki_context_words_after` as non-negative integer settings. These settings SHALL define how many logical words may be added before and after the sentence-scoped base span.

#### Scenario: Padding settings are applied independently
- **WHEN** `anki_context_scope_mode` is `sentence`
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

### Requirement: Padding Is Applied After Sentence Scoping
When sentence scope is active, the system SHALL first calculate the base context using abbreviation-aware sentence-boundary logic, then expand the resulting literal source span by the configured number of logical words before and after that base span.

#### Scenario: Manual subtitle sentence is expanded by words
- **WHEN** `anki_context_scope_mode` is `sentence`
- **AND** `anki_context_words_before` is `3`
- **AND** `anki_context_words_after` is `1`
- **AND** the base sentence span begins at `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`
- **AND** the joined context is `VAZ Fit for the job ## Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH ### Ein Unternehmen der Koder-Gruppe`
- **THEN** the exported context SHALL include the preceding words `for the job`
- **AND** the exported context SHALL include the following word `Ein`
- **AND** structural markers such as `##` and `###` inside the selected substring SHALL be preserved

#### Scenario: Disabled padding remains sentence-only
- **WHEN** `anki_context_scope_mode` is `sentence`
- **AND** `anki_context_words_before` is `0`
- **AND** `anki_context_words_after` is `0`
- **THEN** the exported context SHALL match the sentence-scoped result before word padding

### Requirement: Optional Auto-Subtitle Word-Window Fallback
The context extraction system SHALL expose `anki_context_auto_word_window` (default `false`). When enabled, and when subtitles are identified as auto-generated or sentence-unreliable, the system SHALL bypass sentence-terminator scanning and calculate context directly from the selected span plus `anki_context_words_before` and `anki_context_words_after`.

#### Scenario: Word window bypasses punctuation scanning
- **WHEN** `anki_context_auto_word_window` is `true`
- **AND** subtitles are identified as auto-generated or sentence-unreliable
- **AND** the joined context contains periods inside abbreviations such as `i. d. Opf. GmbH`
- **THEN** the system SHALL NOT use `.`, `!`, or `?` to decide the context boundaries
- **AND** the context boundaries SHALL be based on logical word positions relative to the selected span

#### Scenario: Uncertain detection keeps sentence behavior
- **WHEN** `anki_context_auto_word_window` is `true`
- **AND** the system cannot reliably determine that subtitles are auto-generated or sentence-unreliable
- **THEN** the system SHALL keep sentence-based extraction behavior
