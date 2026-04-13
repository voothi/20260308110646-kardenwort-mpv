## ADDED Requirements

### Requirement: Automatic Sentence Punctuation Recovery
The context extraction system SHALL automatically append a terminal period to exported sentences if they start with a capital letter and follow a known sentence boundary (start of block or preceding punctuation).

#### Scenario: Appending period to capitalized sentence
- **GIVEN** a subtitle source "Vorwort. Die Luftfahrtbranche befindet sich im Umbruch"
- **WHEN** the context "Die Luftfahrtbranche befindet sich im Umbruch" is extracted
- **THEN** the system SHALL append a period, resulting in "Die Luftfahrtbranche befindet sich im Umbruch."

#### Scenario: Preserving existing punctuation
- **WHEN** an extracted sentence already ends with terminal punctuation (`.`, `!`, or `?`)
- **THEN** the system SHALL NOT append an additional period.

#### Scenario: Ignoring lowercase fragments
- **WHEN** an extracted text segment starts with a lowercase letter
- **THEN** the system SHALL NOT append a terminal period, treating it as a phrase fragment.
