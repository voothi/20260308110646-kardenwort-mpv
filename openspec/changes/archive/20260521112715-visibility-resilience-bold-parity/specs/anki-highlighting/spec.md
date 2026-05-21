## ADDED Requirements

### Requirement: Bold Highlighting Parity
The highlighting engine SHALL dynamically respect the `anki_highlight_bold` configuration state for database-matched phrase-only highlights, ensuring visual parity with single-word matches. Furthermore, manual interactive selections MUST strictly enforce standard font weight (`{\b0}`) regardless of the `anki_highlight_bold` setting.

#### Scenario: Database phrase matches with bold highlighting enabled
- **WHEN** `anki_highlight_bold` is set to "yes"
- **AND** a multi-word phrase from the database is matched
- **THEN** the highlighted phrase SHALL be formatted with bold (`{\b1}`) tags

#### Scenario: Database phrase matches with bold highlighting disabled
- **WHEN** `anki_highlight_bold` is set to "no"
- **AND** a multi-word phrase from the database is matched
- **THEN** the highlighted phrase SHALL be formatted with standard weight (`{\b0}`) tags

#### Scenario: Manual interactive selections always standard weight
- **WHEN** the user makes a manual selection in the Drum Window
- **THEN** the selected words SHALL always be rendered with standard font weight (`{\b0}`) even if `anki_highlight_bold` is set to "yes"
