## Why

The current Anki interaction and highlighting engine exhibits three critical technical gaps:
1. **Marker-Injection Anchoring**: Context extraction uses geometric midpoint "guessing" instead of the logical Multi-Pivot maps, leading to research drift.
2. **Three-Phase Highlighting**: The visual engine lacks the Phase 2 (Green) palette, causing local fragmented matches to be incorrectly rendered as Phase 3 (Purple).
3. **Fractional Indexing**: Punctuation and brackets currently skip logical indexing, preventing granular selection and leading to "snapping" artifacts during mouse interaction.

## What Changes

- **Logical Anchoring**: Refactor `extract_anki_context` to utilize the Multi-Pivot logical coordinate map.
- **Phase 2 Implementation**: Add "Local Fuzzy Match" detection to the highlighter, rendering single-line fragmented matches in **Green (#00FF00)**.
- **Fractional Indexing**: Update the tokenizer to assign decimal logical indices (e.g., 1.1) to punctuation and brackets, enabling precise hit-testing and selection.
- **Selection Protection**: (Refinement) Ensure Pointer Jump Sync does not collapse active ranges when interacting with multiple gaps.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window-indexing`: Refine Marker-Injection to mandate logical coordinate search; update Token Atomization to include non-word tokens via fractional indices.
- `window-highlighting-spec`: Fully implement the Three-Phase Match Evaluation, including the Phase 2 (Green) local match palette.

## Impact

- **Affected Code**: `scripts/lls_core.lua`.
- **User Interface**: Sub-word selection precision and improved highlighting accuracy.
