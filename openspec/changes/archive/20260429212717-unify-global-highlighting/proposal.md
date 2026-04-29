## Why

The Drum Mode (C) and Drum Window (W) currently exhibit inconsistent highlighting for punctuation and brackets, particularly when these symbols are separated from their parent words by line wraps, multiple spaces, or subtitle entry boundaries. This creates a visual disparity and degrades the premium feel of the interface during language study.

## What Changes

- **Unify Rendering Logic**: Refactor both `draw_drum` and `draw_dw` to use a shared, three-pass semantic engine.
- **Global Token Stream**: Implement a whitespace-blind, cross-subtitle neighbor search for punctuation coloring.
- **Tokenizer Update**: Modify `build_word_list_internal` to atomize `\N` and `\h` tokens, preventing them from blocking color flow.
- **Eliminate Disparity**: Ensure that "surgical" punctuation uncoloring is replaced by intelligent "phrase-aware" coloring across all modes.

## Capabilities

### New Capabilities
- `global-semantic-coloring`: A shared engine that performs whitespace-blind, cross-boundary neighbor searching to flow highlight colors to punctuation.

### Modified Capabilities
- `unified-drum-rendering`: Requirements updated to include the global semantic pass for punctuation and cross-subtitle highlighting consistency.
- `drum-window-high-precision-rendering`: Requirements updated to support global stream-based coloring instead of row-centric coloring.

## Impact

- `lls_core.lua`: Significant refactor of `draw_drum`, `draw_dw`, and `build_word_list_internal`.
- Performance: Slight overhead due to global pre-pass, mitigated by layout caching.
- UX: Consistent, high-fidelity highlighting across all viewing modes.
