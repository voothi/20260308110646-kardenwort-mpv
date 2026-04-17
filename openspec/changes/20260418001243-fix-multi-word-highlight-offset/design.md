## Context

The `calculate_highlight_stack` function in `lls_core.lua` implements three phases of highlighting:
1. **Phase 1: Local Sequence Match** - Verifies if the token and its neighbors match the multi-word term consecutively.
2. **Phase 2: Context Match** - Performed if Phase 1 passes and strict context is enabled. It uses an absolute `SentenceSourceIndex` (exported from the Drum Window) to anchor the highlight to a specific occurrence.
3. **Phase 3: Split Matching** - A fallback for non-contiguous or broken sequences, coloring them purple.

The current implementation of Phase 2 logic (lines 863-868) is:
```lua
if data.index and target_l_idx then
    context_satisfied = (data.index == target_l_idx)
    if context_satisfied then match_count = 2 end 
end
```
`data.index` contains the index of the *start* of the selection. For multi-word terms, `target_l_idx` only matches `data.index` for the first word of the phrase. All subsequent words in the phrase fail this check and fall back to the purple Phase 3 styling, even if they are in the correct sequence.

## Goals / Non-Goals

**Goals:**
- Ensure all words in a multi-word phrase correctly validate against the `data.index` anchor.
- Restore consistent Orange highlighting for contiguous phrases exported via Anki.
- Maintain strict context matching to prevent highlight "bleed" into identical phrases at different indices.

**Non-Goals:**
- Removing the `data.index` check (it is critical for precision).
- Changing Phase 3 "Split Match" behavior for actual broken sequences.

## Decisions

- **Offset-Aware Index Matching**: Modify the comparison to calculate the relative position of the current token within the phrase.
- **Formula**: The expected `target_l_idx` for a token is `data.index + (term_offset - 1)`.
- **Logic Placement**: Update line 865 in `calculate_highlight_stack` to use this offset-aware comparison.

## Risks / Trade-offs

- **Risk**: If `term_offset` is incorrectly calculated, it could break highlighting for the entire phrase. 
- **Mitigation**: `term_offset` is already provided by the loop iterating through `term_clean`, making the fix straightforward and low-risk.
