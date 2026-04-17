## Context

The current `lls_core.lua` uses a token-driven highlighting system. While more modular, the implementation of relative word lookups across subtitle boundaries was broken during the transition, causing highlighting malfunctions at segment edges. Additionally, phrase coloring and subtitle merging behaviors diverged from the established user experience.

## Goals / Non-Goals

**Goals:**
- Fix cross-segment word lookups in the highlighting engine.
- Restore the original "Split vs. Contiguous" coloring logic.
- Align the Anki export logic with the token-based architecture.
- Optimize the core highlighting loop to reduce redundant tokenization/iteration calls.

**Non-Goals:**
- Rewriting the entire tokenization engine.
- Changing the ASS tag processing logic.

## Decisions

- **Relative Index Adjustment**: Modify `get_relative_word_text` to decrement `target_logical_idx` by the current sub's word count when moving forward across a segment boundary, and vice versa when moving backward. This restores parity with the old index-relative logic while keeping the new token structure.
- **Color Logic Restoration**: Remove the word count threshold check from the contiguous match phase of `calculate_highlight_stack`. Contiguous matches will always be Orange; only the "Split Matching" (Phase 3) will result in Purple highlights.
- **ASS Merge Restoration**: Enable merging in `load_sub` for ASS tracks unless a specific collision is detected.
- **Unified Selection Processing**: Update `dw_anki_export_selection` to use `get_sub_tokens` and iterate via token indices. This ensures that the selection logic matches the rendering logic exactly, preventing off-by-one errors in word selection.
- **Loop Optimization**: Cache the number of words in a subtitle (`sub.word_count`) alongside tokens to avoid re-counting in the neighbor check loop.

## Risks / Trade-offs

- **Memory**: Caching word counts and tokens increases memory usage slightly per subtitle segment.
- **Complexity**: The relative index calculation across segments is inherently sensitive to subtitle timing gaps (1.5s threshold), requiring careful boundary checking.
