# Global Semantic Coloring

## Purpose
Ensure that highlighting is strictly bound to user-selected tokens and database-matched terms, preventing visual ambiguity caused by automatic color propagation.

## Requirements

### Requirement: Strict Highlight Binding
Highlight colors SHALL strictly apply only to the explicitly selected tokens and terms found in the dictionary. There SHALL BE no automatic color inheritance or "bleeding" to adjacent non-selected punctuation symbols or whitespace.

#### Scenario: Selected word adjacent to bracket
- **WHEN** the word `UMGEBUNG` is selected in the string `[UMGEBUNG]`
- **THEN** only `UMGEBUNG` SHALL be highlighted.
- **AND** the brackets `[` and `]` SHALL remain in the default (white/unselected) color.

### Requirement: Independent Line-Break Handling
The tokenizer SHALL preserve ASS/SRT line-break sequences (`\N`, `\h`) as logical tokens, but they SHALL NOT be used as bridge points for semantic highlight propagation.
