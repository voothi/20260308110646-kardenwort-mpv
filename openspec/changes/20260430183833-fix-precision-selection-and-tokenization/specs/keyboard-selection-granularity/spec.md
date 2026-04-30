## MODIFIED Requirements

### Requirement: Modifier-Driven Selection Granularity
The Drum Window SHALL support granular token-level selection using the Shift modifier with arrow keys.
- **Normal Arrow Keys**: Move the cursor between adjacent words (tokens with `is_word=true`).
- **Shift + Arrow Keys**: Move the cursor between all logical tokens, including punctuation and symbols, BUT excluding pure whitespace tokens.

#### Scenario: Selecting punctuation with keyboard
- **GIVEN** a subtitle line "Hello, world!"
- **WHEN** the cursor is at "Hello" and the user presses Shift + Right
- **THEN** the cursor SHALL move to the comma token `,`.
- **AND** it SHALL NOT stop on the space between "Hello," and "world".

#### Scenario: Word-only navigation
- **GIVEN** a subtitle line "[UMGEBUNG]"
- **WHEN** the user presses Right (without Shift) from the start of the line
- **THEN** the cursor SHALL move directly to "UMGEBUNG", skipping the bracket `[`.
