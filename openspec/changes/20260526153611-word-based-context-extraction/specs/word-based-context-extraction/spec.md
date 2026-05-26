## ADDED Requirements

### Requirement: Word-Based Context Extraction Mode
The system SHALL support extracting context strictly by word boundaries rather than sentence punctuation, when configured to do so. A new script option `anki_context_mode` SHALL dictate the extraction behavior. When `anki_context_mode` is set to `"word"`, the system SHALL bypass the forward/backward terminator scanning logic completely.

#### Scenario: Word mode enabled
- **WHEN** `anki_context_mode` is `"word"`
- **THEN** the system SHALL NOT search for `.`, `!`, or `?` to determine sentence boundaries
- **AND** the system SHALL calculate the context span purely based on word indices relative to the selection

### Requirement: Configurable Word Padding
When in word-based context extraction mode, the system SHALL extract a configurable number of words preceding and succeeding the selected term. The padding SHALL be controlled by `anki_context_words_before` and `anki_context_words_after`.

#### Scenario: Padded extraction
- **WHEN** the selection is `"apple"`
- **AND** `anki_context_words_before` is `2` and `anki_context_words_after` is `3`
- **AND** the joined context is `"He said that the red apple is very tasty and sweet"`
- **THEN** the extracted context SHALL be `"that the red apple is very tasty"`

#### Scenario: Out of bounds padding
- **WHEN** the padding requests more words than exist in the joined context block
- **THEN** the system SHALL clamp the boundaries to the beginning and end of the joined context block
- **AND** the system SHALL NOT throw an error or include trailing `\0` sentinels

### Requirement: Default Context Mode Compatibility
The system SHALL preserve backward compatibility by defaulting to sentence-based extraction when `anki_context_mode` is not explicitly set to `"word"`.

#### Scenario: Default mode
- **WHEN** the user does not specify `anki_context_mode` in `mpv.conf`
- **THEN** the system SHALL behave as if `anki_context_mode="sentence"`
- **AND** the existing punctuation-aware scanning logic SHALL apply
