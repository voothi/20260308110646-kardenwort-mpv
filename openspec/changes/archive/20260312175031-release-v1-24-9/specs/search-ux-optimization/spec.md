## ADDED Requirements

### Requirement: Bash-Style Word Deletion
The search HUD SHALL support a `Ctrl+W` shortcut that deletes the entire word or whitespace block to the left of the current cursor position.

#### Scenario: Deleting a word
- **WHEN** the user types a query like "word1 word2" and the cursor is at the end
- **THEN** pressing `Ctrl+W` SHALL remove "word2", leaving "word1 ".

### Requirement: Selection-Prioritized Deletion
When a text selection is active, word-deletion commands SHALL prioritize removing the selected range.

#### Scenario: Deleting selected text
- **WHEN** a range of text is highlighted in the search bar
- **THEN** pressing `Ctrl+W` SHALL delete the highlighted text rather than the preceding word.
