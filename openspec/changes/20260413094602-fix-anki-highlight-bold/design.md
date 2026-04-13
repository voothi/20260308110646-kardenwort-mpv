## Context

The `lls_core.lua` script contains two primary subtitle renderers: `draw_drum` (classic scrolling mode) and `draw_dw` (unified Drum Window). Word-level highlighting logic involving surgical punctuation isolation and bolding was duplicated between these renderers. During a recent update to the Drum Window, the conditional bolding logic (`anki_highlight_bold`) was omitted, leading to the reported regression.

## Goals / Non-Goals

**Goals:**
- Restore `anki_highlight_bold` functionality in the Drum Window.
- Eliminate logic duplication in word-level formatting.
- Harden the rendering engine against future regressions in visual consistency.

**Non-Goals:**
- modifying the core matching logic (`calculate_highlight_stack`).
- adding new UI features to the Drum Window beyond bolding.

## Decisions

### 1. Extract Unified Word Formatter
We will create a helper function `format_highlighted_word(word, h_color, base_color, is_phrase, bold_state, use_1c)` to encapsulate the surgical punctuation isolation and bolding logic.

**Rationale:** The string manipulation required for "surgical" highlighting (isolating punctuation from the colored word body) is complex and error-prone. Centralizing it ensures that any bug fixes or improvements (like this bolding fix) propagate to both renderers automatically.

**Alternative Considered:** Manual porting of the bolding logic into `draw_dw`.
*   **Pros:** Lower change surface.
*   **Cons:** Maintains technical debt; future changes to highlight looks (e.g., adding italic support) would need to be double-applied.

### 2. Standardize Bold Resets
The unified formatter will explicitly use `{\b1}` and `{\b%s}` (where `%s` is the base bold state) to wrap highlights. For the Drum Window, the base bold state will be assumed to be `0` (non-bold) since there are no current configuration options for line-level bolding in that mode.

## Risks / Trade-offs

- **[Risk]** Unified function overhead → **Mitigation**: The function will only perform string formatting and regex matching on single words, which is highly efficient in Lua. No database or expensive state lookups will be included in the formatter.
- **[Trade-off]** Refactoring a stable renderer (`draw_drum`) → **Mitigation**: We will verify that `draw_drum` remains visually identical after the refactor.
