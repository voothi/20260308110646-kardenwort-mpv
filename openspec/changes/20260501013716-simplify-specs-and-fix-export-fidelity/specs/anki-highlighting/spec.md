## DEPRECATED Requirements

### Requirement: Semantic Punctuation Coloring (Req 103)
**DEPRECATED**: The system SHALL NOT implement multi-pass coloring for non-word tokens. Highlighting is strictly restricted to word-tokens to ensure visual clarity.

### Requirement: Atomic Tokenization for Logistical/Metadata Units (Req 114)
**DEPRECATED**: Logistical symbols and metadata brackets SHALL NOT be treated as part of the word-character definition. The tokenizer SHALL treat them as separate punctuation/symbol tokens to align with the Surgical Model.

## MODIFIED Requirements

### Requirement: Strict Highlight Binding
**UPDATED**: Highlighting colors SHALL strictly apply only to explicitly selected tokens and terms. Brackets `[]` and other surrounding punctuation SHALL remain the default color, even if the enclosed word is highlighted.
