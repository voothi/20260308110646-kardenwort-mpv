# Capability: scanner-parser

A robust, state-machine based tokenization engine for Lua that replaces the regex-split approach. It ensures precise word boundaries for highlighting and selection.

## ADDED Requirements

### Requirement: Language Character Support
The tokenizer must recognize German and English characters as word-formers, ensuring words like "Apfelsaft" or "Österreich" are treated as atomic units for highlighting.

#### Scenario: German word recognition
- **WHEN** text contains "Häuser-Besitzer!"
- **THEN** it should tokenize into: `["Häuser", "-", "Besitzer", "!"]`

### Requirement: Metadata Protection
Bracketed content (often used for speaker names or sound effects like `[ Music ]`) should be atomized so that the inner text is treatable as one unit for metadata-aware stripping.

#### Scenario: Bracketed tag atomization
- **WHEN** text contains "[Speaker] Hello"
- **THEN** it should tokenize into: `["[Speaker]", " ", "Hello"]`

### Requirement: ASS Tag Transparency
ASS tags like `{\pos(40,40)}` MUST be preserved as single tokens and ignored by any logic that counts "Visible Words," ensuring that they don't corrupt the index of the text it surrounds.

#### Scenario: ASS tag preservation
- **WHEN** text contains "Hello {\tag} World"
- **THEN** it should tokenize into: `["Hello", " ", "{\tag}", " ", "World"]`
