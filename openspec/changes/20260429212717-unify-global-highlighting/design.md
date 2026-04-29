## Context

Currently, `lls_core.lua` implements rendering for Drum Mode (C) and Drum Window (W) using localized logic. Each subtitle entry is processed independently, and punctuation highlighting (coloring brackets/quotes based on adjacent words) is restricted to the current visual line or subtitle entry. This causes "white brackets" when a word and its punctuation are separated by a line wrap or a subtitle boundary.

## Goals / Non-Goals

**Goals:**
- Implement a **Global Token Stream Architecture** where semantic coloring flows across subtitle boundaries.
- Unify the selection and highlighting logic for both C and W modes.
- Optimize the tokenizer to handle line-break tokens (`\N`, `\h`) as atomic units.
- Ensure whitespace-blind neighbor searching for robust punctuation coloring.

**Non-Goals:**
- Changing the visual style or colors of the highlights.
- Modifying the underlying database phrase matching logic.
- Rewriting the layout engine (wrapping) itself.

## Decisions

### 1. Shared Semantic Engine
We will move highlight calculation out of the localized rendering loops and into a shared three-pass engine:
- **Pass 1 (Priority)**: Tag every token with its selection priority (Persistent > Manual > Database).
- **Pass 2 (Semantic Flow)**: Perform a global, whitespace-blind neighbor search across all visible subtitles to color punctuation.
- **Pass 3 (Formatting)**: Draw the visual rows using the finalized metadata.

**Rationale**: This decouples the "thinking" (semantic logic) from the "drawing" (ASS formatting), ensuring consistency and making the code easier to maintain.

### 2. Global Neighbor Search Helper
A new recursive function `get_global_neighbor(layout, entry_idx, token_idx, direction)` will be implemented to traverse across subtitle entries in the layout list.

**Rationale**: This is the only way to solve the cross-subtitle highlighting issue without a massive architectural overhaul.

### 3. Atomic Line-Break Tokens
The tokenizer `build_word_list_internal` will be updated to treat `\N` and `\h` as single tokens.

**Rationale**: This prevents these characters from blocking the color flow and simplifies the `is_ignorable` check in the semantic pass.

## Risks / Trade-offs

- **[Risk] Performance Regression** → The global pass only runs on the current viewport (usually < 20 subtitles). Layout caching is already implemented, so the impact will be negligible.
- **[Risk] Tokenizer Regression** → We will use strict regex matches for `\N` and `\h` and verify that standard word splitting remains unaffected.
- **[Trade-off] Memory Usage** → Storing a `token_meta` table for each entry adds some memory overhead, but it is ephemeral and scoped to the current render call.
