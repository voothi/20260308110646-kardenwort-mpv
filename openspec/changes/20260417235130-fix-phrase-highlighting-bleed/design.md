# Design: Phrase Highlighting Precision

## Context

The `lls_core.lua` script uses a multi-phase matching algorithm in `calculate_highlight_stack`. 
- **Phase 1 (Basic Match)**: Checks if the term exists in the subtitle text.
- **Phase 2 (Context Match)**: Verifies neighbors and logical index if `needs_strict` is true.

Currently, `needs_strict` is defined as:
```lua
local needs_strict = Options.anki_context_strict or (#term_clean == 1)
```
This means if a phrase has > 1 word AND the global `anki_context_strict` option is `no`, it skips Phase 2 entirely. Combined with an expanded 30-line window for phrases, this causes all identical phrases in that window to be highlighted.

## Goals / Non-Goals

**Goals:**
- Prevent multiple high-lights for the same phrase within the Drum Window when only one was selected.
- Ensure multi-word phrases respect context or logical position when "Local" (non-global) mode is active.
- maintain performance for large subtitle files.

**Non-Goals:**
- Changing the default behavior for *global* highlighting (where matches are desired across the whole file).
- Removing the +/- 15 line window expansion (which is useful for subtitle time-alignment jitter).

## Decisions

### 1. Refine `needs_strict` Condition
We will modify the condition to ensure that if we are targeting a specific subtitle index (the one the user clicked), we apply strict matching regardless of word count, OR at least ensure the word index matches.

### 2. Prioritize Logical Index for Phrases
In the sequential matcher for phrases, we currently just find any occurrence. We should check the `logical_index` more robustly if it's available in the triggering `data`.

### 3. Configurable Strictness
While modifying the code, we will also document that `lls-anki_context_strict=yes` is the recommended fix for users who want maximum precision.

## Risks / Trade-offs

- **Risk**: Stricter matching might cause highlights to disappear if subtitle text is slightly inconsistent (e.g. OCR errors in neighbors).
- **Trade-off**: Slightly more CPU usage during highlighting calculations due to neighbor checks for phrases. This is negligible for modern hardware.
