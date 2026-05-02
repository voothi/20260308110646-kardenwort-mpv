## Context

The current navigation implementation in `lls_core.lua` treats all logical tokens (words, punctuation, symbols) as equal targets for the yellow highlight pointer. While this is necessary for surgical selection of symbols (e.g., brackets or hyphens), it creates a suboptimal experience during vertical navigation (UP/DOWN keys), where the pointer often lands on lines containing only punctuation, making it appear as if the pointer has "disappeared."

## Goals / Non-Goals

**Goals:**
- Enforce word-only targeting for all vertical navigation jumps.
- Skip lines that do not contain any tokens classified as words.
- Maintain existing character-level precision for horizontal navigation (LEFT/RIGHT) and mouse interaction.
- Simplify the implementation using idiomatic Lua patterns (e.g., `for` loops).

**Non-Goals:**
- Modifying the tokenization logic or how `is_word` is defined.
- Changing the appearance of the highlight pointer itself.

## Decisions

### 1. Hybrid Target Matching
The `dw_closest_word_at_x` function will be extended with an optional `word_only` parameter.
- **Rationale**: This allows vertical navigation to request a strict word-match while allowing mouse hit-testing and horizontal movement to remain permissive.
- **Alternatives**: Creating a separate function `dw_closest_real_word_at_x` was considered but rejected to avoid code duplication in the coordinate-mapping logic.

### 2. Bounded Line Skipping Loop
Vertical navigation will use a `for` loop to scan for the next available line containing at least one word.
- **Rationale**: A `for` loop is more idiomatic and less error-prone than a `while` loop for scanning ranges in a specific direction.
- **Behavior**: If no words are found in the direction of travel, the pointer remains on its current line.

### 3. Decoupling Vertical and Horizontal Selection Granularity
Only `cmd_dw_line_move` will be updated to use strict word-matching. `cmd_dw_word_move` and `dw_build_layout` maps will remain character-inclusive.
- **Rationale**: This satisfies the requirement for "word-only" vertical movement while preserving the "surgical selection" capability for individual characters.

## Risks / Trade-offs

- **[Risk]** User gets "stuck" on a line if no words exist above or below. → **[Mitigation]** This is acceptable as it correctly reflects the lack of meaningful content; the pointer will remain visible on the last known word.
- **[Risk]** Performance impact of scanning multiple lines. → **[Mitigation]** Subtitle tracks are typically small, and the scan loop only performs O(1) lookups on cached tokens.
