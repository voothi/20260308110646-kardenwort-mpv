## Context

The current `lls_core.lua` script uses a unified tokenization and highlighting model that occasionally sacrifices precision for visual "completeness". Specifically, punctuation and brackets are often attached to words, and the rendering engine spreads highlight colors to neighboring symbols to create a "connected" look. While aesthetically pleasing, this creates friction for users who need exact control over vocabulary mining, especially when using limited input devices like remote controls.

## Goals / Non-Goals

**Goals:**
- Separate logistical symbols (brackets, slashes, hyphens) from alphanumeric word tokens.
- Restore character-level navigation precision for non-word symbols using standard `LEFT`/`RIGHT` arrow keys.
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

### 2. Universal Precision Navigation
- **Decision**: Make `LEFT` and `RIGHT` arrows land on every logical token (word or symbol), excluding only pure whitespace.
- **Rationale**: This is the simplest and most robust solution for users without access to `Alt` or `Ctrl` modifiers (e.g., on a remote control). It guarantees the ability to land on any bracket or symbol to start a selection.
- **Alternatives**: Using `Alt` or `Ctrl` for precision stepping. Rejected because the target hardware (remote controls) does not have these modifiers.

### 3. Removal of Semantic Pass
- **Decision**: Completely delete `apply_global_semantic_pass` and its calls in the rendering loop.
- **Rationale**: Unambiguous display requires that if a token is not in the selection set, it should not be colored. Spreading color to neighbors creates "false positives" in the visual UI compared to the actual exported text.
- **Alternatives**: Modifying the semantic pass to be "smarter" about when to spread. Rejected in favor of the "simplicity" directive.

## Risks / Trade-offs

- **Risk**: Moving across lines with many symbols (commas, brackets) requires more key presses.
- **Mitigation**: The clarity and ability to start selections on any character without a mouse is a high-value improvement for precision mining.
- **Risk**: "Dictionary" highlights (Orange/Purple) may look more fragmented.
- **Mitigation**: This is an intentional trade-off for "straightforwardness" and "unambiguous selection" as requested by the user.
