## Context

The current `lls_core.lua` script uses a unified tokenization and highlighting model that occasionally sacrifices precision for visual "completeness". Specifically, punctuation and brackets are often attached to words, and the rendering engine spreads highlight colors to neighboring symbols to create a "connected" look. While aesthetically pleasing, this creates friction for users who need exact control over vocabulary mining.

## Goals / Non-Goals

**Goals:**
- Separate logistical symbols (brackets, slashes, hyphens) from alphanumeric word tokens.
- Restore character-level navigation precision for non-word symbols when holding `Shift`.
- Enforce strict selection boundaries where the visual highlight perfectly matches the selection range.
- Eliminate automatic color spreading in the rendering pass.

**Non-Goals:**
- Changing the underlying ASS/SRT parsing logic.
- Modifying the Anki export format (CSV/TSV structure).
- Introducing complex regex-based "smart" selection that guesses user intent.

## Decisions

### 1. Tokenization Refinement
- **Decision**: Update `is_word_char` to only include `%w` (alphanumeric) and `'` (apostrophe).
- **Rationale**: Symbols like `[` `]` `-` and `/` are often logistical or metadata markers in subtitles. Treating them as separate tokens allows for surgical selection and prevents them from being auto-highlighted when a word inside them is clicked.
- **Alternatives**: Using a complex regex to identify "bracketed phrases" as atomic units. Rejected in favor of simplicity.

### 2. Explicit Navigation Modes
- **Decision**: Use the `shift` parameter in `cmd_dw_word_move` to gate whether punctuation tokens are considered valid landing spots.
- **Rationale**: Standard navigation (without Shift) should remain efficient by skipping over every comma/bracket. Precision selection (with Shift) requires the ability to land on these symbols.
- **Alternatives**: Creating a separate "symbol mode" toggle. Rejected as less intuitive than the standard Shift-select idiom.

### 3. Removal of Semantic Pass
- **Decision**: Completely delete `apply_global_semantic_pass` and its calls in the rendering loop.
- **Rationale**: Unambiguous display requires that if a token is not in the selection set, it should not be colored. Spreading color to neighbors creates "false positives" in the visual UI compared to the actual exported text.
- **Alternatives**: Modifying the semantic pass to be "smarter" about when to spread. Rejected in favor of the "simplicity" directive.

## Risks / Trade-offs

- **Risk**: Users may find selecting hyphenated words more tedious (requiring multiple steps).
- **Mitigation**: The clarity gained in overall selection precision outweighs the minor overhead for hyphenated terms.
- **Risk**: "Dictionary" highlights (Orange/Purple) may look more fragmented.
- **Mitigation**: This is an intentional trade-off for "straightforwardness" and "unambiguous selection" as requested by the user.
