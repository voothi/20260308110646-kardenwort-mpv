## Context

The current `build_word_list` and `compose_term_smart` (lines 412-456 in `lls_core.lua`) use a split-and-regroup strategy that loses contextual information about punctuation and metadata positioning. This results in "parser bugs" where words are highlighted with trailing punctuation or metadata tags are incorrectly split.

## Goals / Non-Goals

**Goals:**
- **Atomic Punctuation**: Every punctuation mark becomes its own token unless it's an internal part of a word (hyphens).
- **Tag Protection**: ASS tags `{...}` and Metadata `[...]` are handled as unbreakable atoms.
- **Improved German Support**: Correctly identifying `äöüß` as word-forming characters.
- **Single-Pass Efficiency**: A robust scanner that runs in O(N).

**Non-Goals:**
- **Full NLP**: No lemmatization or POS tagging (this would require external dependencies).
- **Universal Script Support**: Focus remains strictly on Latin-based alphabets (English, German) and basic Cyrillic if needed. CJK is out of scope.

## Decisions

### 1. State-Machine Scanner
The tokenizer will be implemented as a `while` loop that advances an index `i` through the string.
- When it encounters `{`, it enters a `TAG` state until `}`.
- When it encounters `[`, it enters a `METADATA` state until `]`.
- When it encounters a "Word Character", it enters a `WORD` state until it hits a "Separator".
- When it encounters anything else, it pushes the character as a `SEPARATOR` token.

### 2. Word Character Definition
For performance, we will define a Lua table containing the UTF-8 byte patterns for German characters (`äöüß`) or use a simplified character range check.

### 3. Smart Joining Policy
`compose_term_smart` will be updated to join tokens in the stream with spaces ONLY if neither token is a separator that forbids it (like punctuation or hyphens).

## Risks / Trade-offs

- **Memory**: The scanner approach creates more small string objects (tokens) than the previous approach. For subtitle-sized strings, this is negligible.
- **Highlight Compatibility**: Since we are changing the definition of what a "token" is, existing range selections (Anchor Line/Word) in the FSM might shift. We will mitigate this by ensuring the "word index" in a line remains as intuitive as possible.
