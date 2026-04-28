# Smart Joiner Service

## Purpose
Provide a central, robust logic engine for reconstructing natural-language strings from word and punctuation tokens, ensuring correct spacing according to standard punctuation rules and supporting elliptical reconstruction for fragmented phrases.

## Requirements

### Requirement: Unified Punctuation Spacing Rule (UPSR)
The system SHALL provide a central logic engine (`compose_term_smart`) for reconstructing natural-language strings specifically for UI and OSD display purposes.
- **No Space Before**: No space SHALL be inserted before tokens: `, . ! ? : ; ) ] } … » ” / - " '` as well as En-Dashes and Em-Dashes.
- **No Space After**: No space SHALL be inserted after tokens: `( [ { ¿ ¡ « „ “ / - " '` as well as En-Dashes and Em-Dashes.
- **Default**: A single space SHALL be inserted between word tokens.
- **Constraint**: This rule SHALL NOT apply to TSV mining exports, which require literal preservation.

#### Scenario: UI joining with punctuation
- **WHEN** joining "word" and "." for OSD display
- **THEN** the smart joiner SHALL return "word." without a space.

#### Scenario: Preserving compound words
- **WHEN** joining "Marken", "-", and "Discount".
- **THEN** the reconstructed string SHALL be "Marken-Discount".

### Requirement: Elliptical Joiner Support
The engine SHALL support the injection of ellipses when reconstructing non-contiguous (split) phrases from the `ctrl_pending_set` or multi-segment ranges.
- **Separator**: ` ... ` (space-padded ellipsis).
- **Rationale**: Visually signifies that words are part of a unified mining record despite being non-contiguous in the source text.

#### Scenario: Reconstructing a split phrase
- **WHEN** the user selects "Ich" from line 1 and "komme" from line 10.
- **THEN** the smart joiner SHALL return: "Ich ... komme".

### Requirement: Adaptive Gap Detection
The service SHALL dynamically evaluate if a gap exists between two tokens based on their logical coordinates.
- **Gap Trigger**: A gap is identified if:
    - Tokens are on the same line but are non-adjacent (`m.word > last_m.word + 1`).
    - Tokens are on different lines and the first token is not the last word of its line, OR the second token is not the first word of its line.
