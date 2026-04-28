## MODIFIED Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
The system SHALL provide a central logic engine (`compose_term_smart`) for reconstructing natural-language strings specifically for UI and OSD display purposes.
- **No Space Before**: No space SHALL be inserted before tokens: `, . ! ? : ; ) ] } … » ” / - " '` as well as En-Dashes and Em-Dashes.
- **No Space After**: No space SHALL be inserted after tokens: `( [ { ¿ ¡ « „ “ / - " '` as well as En-Dashes and Em-Dashes.
- **Default**: A single space SHALL be inserted between word tokens.
- **Constraint**: This rule SHALL NOT apply to TSV mining exports, which require literal preservation.

#### Scenario: UI joining with punctuation
- **WHEN** joining "word" and "." for OSD display
- **THEN** the smart joiner SHALL return "word." without a space.
