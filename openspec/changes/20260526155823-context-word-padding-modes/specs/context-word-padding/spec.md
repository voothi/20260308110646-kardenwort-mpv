## ADDED Requirements

### Requirement: Configurable Context Word Padding
The context extraction system SHALL expose `anki_context_words_before` and `anki_context_words_after` as non-negative integer settings. These settings SHALL define how many logical words may be added before and after the sentence-scoped context.

#### Scenario: Padding settings are applied independently
- **WHEN** `anki_context_words_before` is `3`
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
The system SHALL first calculate context boundaries using the existing abbreviation-aware sentence logic. After the sentence-scoped base span is found, the system SHALL expand that span by `anki_context_words_before` and `anki_context_words_after`.

#### Scenario: Manual subtitle sentence is expanded by words
- **WHEN** `anki_context_words_before` is `3`
- **AND** `anki_context_words_after` is `1`
- **AND** the base sentence span begins at `Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH`
- **AND** the joined context is `VAZ Fit for the job ## Verkehrs-Ausbildungs-Zentrum i. d. Opf. GmbH ### Ein Unternehmen der Koder-Gruppe`
- **THEN** the exported context SHALL include the preceding words `for the job`
- **AND** the exported context SHALL include the following word `Ein`
- **AND** structural markers such as `##` and `###` inside the selected substring SHALL be preserved

#### Scenario: Trailing punctuation on the padded word is preserved
- **WHEN** `anki_context_words_after` includes a following word that is immediately followed by punctuation
- **THEN** the exported context SHALL include that adjacent punctuation with the padded word

#### Scenario: Disabled padding remains sentence-only
- **WHEN** `anki_context_words_before` is `0`
- **AND** `anki_context_words_after` is `0`
- **THEN** the exported context SHALL match the sentence-scoped result before word padding
