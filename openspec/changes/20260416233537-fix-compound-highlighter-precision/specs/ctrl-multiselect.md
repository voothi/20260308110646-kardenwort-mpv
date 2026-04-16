## ADDED Requirements

### Requirement: Punctuation Preservation in Term Composition
Composed terms from multi-word selections MUST preserve all characters of the selected tokens, only stripping punctuation from the very start and end of the final composed string.

#### Scenario: Selection containing a dash
- **WHEN** Composing a term from tokens including "-"
- **THEN** The "-" MUST NOT be stripped from the internal parts of the term.
