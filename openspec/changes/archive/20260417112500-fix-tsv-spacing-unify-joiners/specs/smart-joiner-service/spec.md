## ADDED Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
The system SHALL provide a central logic engine that accepts a list of word/punctuation tokens and reconstructs a single natural-language string with correct spacing.

#### Scenario: No space before punctuation
- **WHEN** a token `T` matches a "no-space-before" symbol (`,`, `.`, `!`, `?`, `:`, `;`, `)`, `]`, `}`, `…`, `»`, `”`)
- **THEN** it SHALL be joined to the preceding token without a space.

#### Scenario: No space after punctuation
- **WHEN** a token `T` matches a "no-space-after" symbol (`(`, `[`, `{`, `¿`, `¡`, `«`, `“`)
- **THEN** the subsequent token SHALL be joined to `T` without a space.

#### Scenario: Space between words
- **WHEN** neither the current token nor the next token trigger a "no-space" rule
- **THEN** a single space SHALL be inserted between them.
