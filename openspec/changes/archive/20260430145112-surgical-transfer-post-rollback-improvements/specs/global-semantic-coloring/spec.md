## ADDED Requirements

### Requirement: Global Semantic Color Flow
The system SHALL implement a post-processing semantic engine that propagates highlight colors from words to adjacent punctuation symbols across subtitle entry boundaries and visual line wraps. This engine SHALL operate as a read-only scan over the finalized highlight color array, AFTER `calculate_highlight_stack` has completed its depth/intersection calculations.

#### Scenario: Trailing punctuation inherits word color
- **WHEN** a word token is highlighted in Orange (contiguous depth)
- **AND** the next token in the visible sequence is a punctuation symbol (e.g., `!`, `.`, `,`)
- **AND** that punctuation token has no existing highlight priority (i.e., is currently uncolored)
- **THEN** the punctuation token SHALL inherit the Orange color of the preceding word.

#### Scenario: Leading punctuation inherits following word color
- **WHEN** a punctuation symbol (e.g., `[`, `(`) is at the start of a subtitle entry
- **AND** the next word token in the same entry is highlighted
- **AND** the punctuation token has no existing highlight priority
- **THEN** the punctuation symbol SHALL inherit the highlight color of the following word.

#### Scenario: Internal punctuation between highlighted words
- **WHEN** two adjacent word tokens belong to the same highlighted phrase (same color, same record)
- **AND** a punctuation or symbol token exists between them (e.g., comma, hyphen)
- **AND** that token has no existing highlight priority
- **THEN** the intervening token SHALL inherit the shared color of the surrounding words.

#### Scenario: Punctuation across subtitle boundaries
- **WHEN** a highlighted word ends one subtitle entry
- **AND** a punctuation symbol begins the next subtitle entry in the rendering window
- **AND** the punctuation token has no existing highlight priority
- **THEN** the semantic engine SHALL propagate the highlight color across the boundary to the punctuation token.

#### Scenario: Multi-space skip
- **WHEN** a highlighted word is separated from an adjacent punctuation symbol by one or more whitespace tokens
- **THEN** the semantic engine SHALL skip whitespace tokens and propagate the color to the punctuation symbol.

### Requirement: Atomic Line-Break Tokenization
The tokenizer SHALL treat ASS/SRT line-break sequences (`\N`, `\h`) as atomic tokens to ensure they do not interfere with semantic color propagation.

#### Scenario: Line-break between word and bracket
- **WHEN** a literal line-break `\N` exists between a highlighted word and its trailing bracket
- **THEN** the semantic engine SHALL skip the line-break token and color the bracket correctly.

### Requirement: Non-Destructive Post-Processing Constraint
The semantic coloring engine SHALL NOT modify the output of `calculate_highlight_stack`. It SHALL only fill in uncolored token slots in the resulting color array. Pre-existing highlight assignments (selection colors, intersection colors, depth colors) SHALL remain unchanged.

#### Scenario: Existing intersection color preserved
- **WHEN** a punctuation token is already colored as Brick (intersection of Orange and Purple)
- **AND** the semantic engine scans it as adjacent to an Orange word
- **THEN** the Brick color SHALL be preserved. The semantic engine SHALL NOT overwrite it.
