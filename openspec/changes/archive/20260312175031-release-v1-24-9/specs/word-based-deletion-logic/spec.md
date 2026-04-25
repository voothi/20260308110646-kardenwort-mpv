## ADDED Requirements

### Requirement: Word-Boundary Detection
The deletion system SHALL utilize the project's internal `get_word_boundary` utility to ensure consistent word identification during deletion.

#### Scenario: Deleting near punctuation
- **WHEN** the cursor is at the end of "hello, world"
- **THEN** pressing `Ctrl+W` SHALL correctly identify the boundary between punctuation and words.

### Requirement: Layout-Agnostic Shortcuts
The word deletion command SHALL be mapped symmetrically across English and Russian keyboard layouts.

#### Scenario: Word deletion in Russian layout
- **WHEN** the user is using the Russian keyboard layout
- **THEN** pressing `Ctrl+Ц` SHALL perform the same word-deletion action as `Ctrl+W`.
