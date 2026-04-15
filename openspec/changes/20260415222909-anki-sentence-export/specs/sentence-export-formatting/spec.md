## ADDED Requirements

### Requirement: Configurable Sentence Threshold
The system SHALL surface a configurable variable determining the minimum word count threshold necessary to classify a specific highlighted selection sequence as a sentence instead of an ordinary word.

#### Scenario: Sequence meets threshold
- **WHEN** a user highlights a sequence consisting of 3 words
- **AND** the application threshold configuration is set to `3`
- **THEN** the selection sequence SHALL be logically categorized as a sentence.

#### Scenario: Sequence falls short of threshold
- **WHEN** a user highlights a sequence consisting of 2 words
- **AND** the threshold is configured as `3`
- **THEN** the highlighted sequence SHALL be classified as a word.

### Requirement: Export Profile Resolution
When executing a TSV record export sequence, the system SHALL evaluate the highlighted sequence categorization and attempt to identify the specifically correlated profile format block (`[fields.word]` or `[fields.sentence]`) from the Anki mapping profile configuration.

#### Scenario: Profile application on export
- **WHEN** the selection is categorized as a sentence
- **THEN** the TSV formatting subsystem SHALL write the selection fields ordered directly according to the structure delimited under the `[fields.sentence]` mapping group.
