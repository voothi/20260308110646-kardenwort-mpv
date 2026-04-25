## ADDED Requirements

### Requirement: Non-Contiguous Character Matching
The search system SHALL support fuzzy matching where characters in the search query match characters in the target string in the correct order, regardless of any intervening characters.

#### Scenario: Searching with partial query
- **WHEN** the user types "hl wrd" in the search bar
- **THEN** the system SHALL match the string "hello world" (as 'h', 'l', ' ', 'w', 'r', 'd' appear in order).

### Requirement: Select All Functionality
The search system SHALL support selecting the entire query buffer for rapid replacement.

#### Scenario: Replacing a query
- **WHEN** the user presses `Ctrl+A` (or `Ctrl+Ф`) in the search bar
- **THEN** the system SHALL select all text in the search buffer.
