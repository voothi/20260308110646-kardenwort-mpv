## REMOVED Requirements

### Requirement: Global Stream-Based Punctuation Rendering
### Requirement: Disciplined Punctuation Stacks

## ADDED Requirements

### Requirement: Word-Only Highlighting
The Drum Window SHALL prioritize word-level highlighting for language acquisition. Punctuation and symbols SHALL NOT be colored independently and SHALL only inherit highlight states if they are part of a contiguous word-token sequence.
- **Rationale**: To reduce architectural complexity and focus on lexical acquisition.

#### Scenario: Uncolored punctuation
- **WHEN** a punctuation mark (e.g., `,` or `!`) appears between two highlighted words
- **THEN** it SHALL NOT inherit any highlight color if it is a separate token.
