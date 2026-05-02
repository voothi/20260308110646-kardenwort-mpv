# Drum Window High Precision Rendering

## Purpose
Ensure visual parity and semantic accuracy in the Drum Window by using a global token stream for highlight propagation and punctuation coloring.
## Requirements
### Requirement: Word-Only Highlighting
The Drum Window SHALL prioritize word-level highlighting for language acquisition. Punctuation and symbols SHALL NOT be colored independently and SHALL only inherit highlight states if they are part of a contiguous word-token sequence.
- **Rationale**: To reduce architectural complexity and focus on lexical acquisition.

#### Scenario: Uncolored punctuation
- **WHEN** a punctuation mark (e.g., `,` or `!`) appears between two highlighted words
- **THEN** it SHALL NOT inherit any highlight color if it is a separate token.


### Requirement: Context-Aware Token Formatting
The `format_highlighted_word` utility SHALL accept and utilize background color and alpha parameters to guarantee absolute visual parity and prevent "lost tags" regressions during surgical injection.

#### Scenario: Rendering highlighted tokens
- **WHEN** a token is processed for highlighting
- **THEN** the formatter SHALL inject explicit `\3c`, `\4c`, `\3a`, and `\4a` tags to lock the aesthetic and restore them to the passed context immediately afterward.
