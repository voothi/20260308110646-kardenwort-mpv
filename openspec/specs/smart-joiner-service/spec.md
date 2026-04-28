# Smart Joiner Service

## Purpose
Provide a central, robust logic engine for reconstructing natural-language strings from word and punctuation tokens, ensuring correct spacing according to standard punctuation rules and supporting elliptical reconstruction for fragmented phrases.

## Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
The system SHALL accept a list of word/punctuation tokens and reconstruct a single natural-language string with correct spacing and strict single-space normalization.
- **Single Space Normalization**: The system SHALL NOT insert multiple spaces between words. All tokens consisting solely of whitespace MUST be collapsed to a single space.
- **Whitespace Awareness**: The system SHALL NOT insert an additional space if either the preceding token ends with whitespace or the following token starts with whitespace.
- **No Space Before**: No space SHALL be inserted before tokens: `, . ! ? : ; ) ] } … » ” / - " '` as well as En-Dashes and Em-Dashes.
- **No Space After**: No space SHALL be inserted after tokens: `( [ { ¿ ¡ « „ “ / - " '` as well as En-Dashes and Em-Dashes.
- **Default**: A single space SHALL be inserted between word tokens.

#### Scenario: Joining with multiple source spaces
- **WHEN** joining "find", "   ", and "those"
- **THEN** the result SHALL be "find those" (all intermediate whitespace collapsed to a single space)

#### Scenario: Preserving compound words
- **WHEN** joining "Marken", "-", and "Discount".
- **THEN** the reconstructed string SHALL be "Marken-Discount".

### Requirement: Elliptical Joiner Support
The engine SHALL support the injection of ellipses when reconstructing non-contiguous (split) phrases from the `ctrl_pending_set` or multi-segment ranges.
- **Separator**: ` ... ` (strictly space-padded ellipsis with exactly one space on each side).
- **Control**: The joiner SHALL NOT strip the padding around the ellipsis, regardless of standard punctuation rules for dots.
- **Rationale**: Visually signifies that words are part of a unified mining record despite being non-contiguous in the source text.

#### Scenario: Reconstructing a split phrase
- **WHEN** the user selects "Ich" from line 1 and "komme" from line 10.
- **THEN** the smart joiner SHALL return: "Ich ... komme".

### Requirement: Adaptive Gap Detection
The service SHALL dynamically evaluate if a gap exists between two tokens based on their logical coordinates.
- **Gap Trigger**: A gap is identified if:
    - Tokens are on the same line but are non-adjacent (`m.word > last_m.word + 1`).
    - Tokens are on different lines and the first token is not the last word of its line, OR the second token is not the first word of its line.
