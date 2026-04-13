## ADDED Requirements

### Requirement: Configurable Highlight Bolding
The rendering engine SHALL respect the `anki_highlight_bold` configuration option when displaying vocabulary highlights in all active renderers, specifically the classic Drum Mode and the unified Drum Window.

#### Scenario: Bold highlights enabled in Drum Window
- **WHEN** `anki_highlight_bold` is set to `yes`
- **AND** a word is rendered in the Drum Window viewport
- **AND** the word is identified as an active Anki highlight
- **THEN** the system SHALL wrap the highlighted segment in ASS bold tags `{\b1}` and `{\b0}`, ensuring the bolding is visually distinct regardless of the line's base font weight.

#### Scenario: Bold highlights disabled
- **WHEN** `anki_highlight_bold` is set to `no`
- **THEN** the system SHALL NOT apply additional bold tags to highlighted words, strictly following the base subtitle styling.
