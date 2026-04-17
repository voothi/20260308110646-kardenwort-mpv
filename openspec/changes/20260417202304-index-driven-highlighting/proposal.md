## Why

The current subtitle highlighting engine relies heavily on fuzzy string matching (`string.find`) and dynamic lookaheads (`get_relative_word`) to identify saved Anki terms. This approach is fundamentally brittle. It causes "highlight bleed" (false positives) in Local Mode, struggles with formatting artifacts like ASS tags, and makes accurately rendering split-verbs (non-contiguous terms) mathematically volatile. As demonstrated by systems like Lute v3, relying on raw string searching for contextual UI rendering scales poorly.

## What Changes

- **Index-Driven Architecture:** Pivot the entire highlighting and selection engine from a string-matching paradigm to a strict Token Stream paradigm.
- **Rich Token Caching:** Subtitles will be parsed once upon load into an array of "Rich Tokens," where every token is assigned a permanent `logical_idx` (if it is a word) and a `visual_idx`.
- **Absolute Targeting:** The `calculate_highlight_stack` function will no longer search strings. Instead, it will verify if the saved Anki term maps to specific sequential `logical_idx` values within the token array, and apply color tags strictly to those addresses.

## Capabilities

### New Capabilities
- `index-driven-highlighting`: A deterministic, index-based tokenization and matching engine that guarantees zero false-positive text selection.

### Modified Capabilities
- `anki-highlighting`: Replaced the fuzzy string-based intersection logic with absolute token-index array matching.

## Impact

- `scripts/lls_core.lua`: Major structural refactor of `calculate_highlight_stack`, `build_word_list_internal`, and the `draw_dw` / `format_sub` rendering pipelines.
- **Performance:** Significant reduction in CPU overhead during rapid scrolling, as expensive regex and string manipulation operations are replaced by simple table lookups.
