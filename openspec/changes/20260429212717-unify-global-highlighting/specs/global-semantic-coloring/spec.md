## ADDED Requirements

### Requirement: Global Semantic Color Flow
The system SHALL implement a shared semantic engine that propagates highlight colors from words to adjacent punctuation symbols across subtitle entry boundaries and visual line wraps.

#### Scenario: Punctuation at start of subtitle entry
- **WHEN** a punctuation symbol (e.g., a bracket) is at the start of a subtitle entry
- **AND** the previous subtitle entry ended with a highlighted word
- **THEN** the punctuation symbol SHALL inherit the highlight color and phrase-status of that word

#### Scenario: Punctuation across multiple spaces
- **WHEN** a punctuation symbol is separated from a highlighted word by multiple whitespace tokens
- **THEN** the system SHALL skip the whitespace and propagate the color to the punctuation symbol

### Requirement: Atomic Line-Break Tokenization
The tokenizer SHALL treat ASS/SRT line-break sequences (`\N`, `\h`) as atomic tokens to ensure they do not interfere with semantic color propagation.

#### Scenario: Line-break between word and bracket
- **WHEN** a literal line-break `\N` exists between a highlighted word and its trailing bracket
- **THEN** the semantic engine SHALL skip the line-break token and color the bracket correctly
