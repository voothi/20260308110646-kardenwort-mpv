## MODIFIED Requirements

### Requirement: Selection Punctuation Preservation
Export logic SHALL NOT automatically strip leading or trailing punctuation symbols if they were explicitly included in the user's selection range.
- This MODIFIES Requirement 128 (Strict Selection Boundaries) to respect user intent.
- **Clarification**: This requirement SHALL take precedence over `clean_anki_term` balanced-bracket stripping. If the user's selection range includes the brackets, they MUST be preserved in the final output.

#### Scenario: Explicitly selecting a bracketed word
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user highlights the entire line including the brackets
- **THEN** the exported term SHALL be "[Musik]"
- **AND NOT** "Musik"
