# Delta: Split-Phrase Context Grounding

## Requirement: Split-Phrase Context Grounding
The context extraction engine (SentenceSource) SHALL ensure that non-contiguous terms are fully preserved and centered within truncated context blocks.

### Scenario: Split phrase in long line
- **GIVEN** a term "pick ... on" is selected across multiple segments
- **AND** the captured sentence block exceeds the word limit (`Options.anki_context_max_words`)
- **WHEN** the SentenceSource is generated
- **THEN** the system SHALL anchor the truncation window around the midpoint of the selection span (`first_word_idx` to `last_word_idx`).
- **AND** the system SHALL NOT use hardcoded character-based truncation (e.g. `sub(1, 100)`) as a primary fallback for non-contiguous matches.

### Scenario: Ellipsis Joiner Neutrality
- **WHEN** the engine searches for term words within the context block to determine grounding
- **THEN** it SHALL ignore the literal `...` joiner used in split-phrase composition to prevent anchoring drift.
