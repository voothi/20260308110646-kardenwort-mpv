# Atomic Punctuation Tokens

## Purpose
Ensure that logistical markers like brackets, slashes, and hyphens are treated as distinct logical tokens, allowing for surgical selection and preventing them from being merged into alphanumeric terms.

## Requirements

### Requirement: Atomic Punctuation Tokenization
The subtitle tokenizer SHALL treat brackets (`[` `]`), slashes (`/`), and hyphens (`-`) as atomic punctuation tokens instead of alphanumeric word characters. This ensures that logistical markers are distinct from the vocabulary terms they enclose or separate.

#### Scenario: Word in brackets
- **WHEN** the subtitle text contains `[UMGEBUNG]`
- **THEN** the tokenizer SHALL produce three tokens: `[`, `UMGEBUNG`, and `]`
- **AND** clicking the word `UMGEBUNG` SHALL only highlight that specific token

#### Scenario: Hyphenated words
- **WHEN** the subtitle text contains `well-known`
- **THEN** the tokenizer SHALL produce three tokens: `well`, `-`, and `known`
