# Capability: scanner-parser

A robust, state-machine based tokenization engine for Lua that replaces the regex-split approach. It ensures precise word boundaries for highlighting and selection.

## ADDED Requirements

### Requirement: Language Character Support
The tokenizer must recognize German and English characters as word-formers, ensuring words like "Apfelsaft" or "Österreich" are treated as atomic units for highlighting.

#### Scenario: German word recognition
- **WHEN** text contains "Häuser-Besitzer!"
- **THEN** it should tokenize into: `["Häuser", "-", "Besitzer", "!"]`

### Requirement: Granular Bracket Tokenization (Metadata Granularity)
Bracketed content (often used for speaker names or sound effects like `[ Music ]`) MUST NOT be atomized into a single massive token. Brackets (`[` and `]`) MUST be treated as regular, individual punctuation tokens. This allows users to accurately target and select individual words residing inside metadata blocks.

#### Scenario: Granular metadata selection
- **WHEN** text contains "[Speaker] Hello"
- **THEN** it should tokenize into: `["[", "Speaker", "]", " ", "Hello"]` (allowing "Speaker" to be individually selected and highlighted).

### Requirement: ASS Tag Transparency
ASS tags like `{\pos(40,40)}` MUST be preserved as single tokens and ignored by any logic that counts "Visible Words," ensuring that they don't corrupt the index of the text it surrounds.

#### Scenario: ASS tag preservation
- **WHEN** text contains "Hello {\tag} World"
- **THEN** it should tokenize into: `["Hello", " ", "{\tag}", " ", "World"]`
