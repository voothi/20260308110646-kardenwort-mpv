## Context

The subtitle export system in `lls_core.lua` currently handles contiguous (Yellow) and non-contiguous (Pink) selections through partially overlapping logic. This has led to regressions where hyphenated terms (e.g., `Marken-Discount`) are incorrectly joined with spaces in Pink mode, and terminal punctuation restoration is inconsistent between modes. Furthermore, keyboard navigation is locked to word-level granularity, preventing users from selecting individual punctuation marks as they can with the mouse.

## Goals / Non-Goals

**Goals:**
- **Centralization**: All export pathways (Range, Set, Point, Copy) must consume the unified `prepare_export_text` service.
- **Verbatim Fidelity**: Pink selections must preserve intermediate non-word tokens (hyphens, slashes) between adjacent members.
- **Punctuation Parity**: Unify sentence boundary detection and terminal punctuation restoration across all mining modes.
- **Input Parity**: Enable keyboard users to select tokens with the same precision as mouse users using Shift modifiers.

**Non-Goals:**
- Changing the underlying indexing system (indices remain logically mapped to words).
- Altering the "word-only" feel of standard keyboard navigation (non-Shift movement remains word-based).

## Decisions

- **Unified String Engine**: Refactor `prepare_export_text` to handle token lookbehind. When adjacent members are detected on the same line, the engine will pull verbatim tokens from the source text instead of assuming a space joiner.
- **Shared Restoration Logic**: Move all terminal punctuation (`[.!?]`) detection and restoration into `prepare_export_text` (gated by `restore_sentence=true`).
- **Scope Relocation**: Move constants like `L_EPSILON` and helpers like `logical_cmp` to the top of the script's logic block to resolve nil-reference errors in the consolidated engine.
- **Shift-Aware Navigation**: Update `cmd_dw_word_move` to filter for all logical tokens (including symbols) when `shift=true`, while maintaining word-only filtering for standard movement.
- **Precision Matching**: Use `logical_cmp` (epsilon-aware comparison) in `draw_dw` and `dw_compute_word_center_x` to ensure fractional logical indices (symbols) are correctly highlighted and positioned.

## Risks / Trade-offs

- **Performance**: Calling `build_word_list_internal` during the export loop is slightly more expensive but necessary for verbatim fidelity.
- **Floating Point Errors**: Reliance on fractional indices for symbols requires strict use of `logical_cmp` to avoid selection "misses".
