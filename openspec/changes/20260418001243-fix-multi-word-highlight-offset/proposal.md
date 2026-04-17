# Proposal: Fix Multi-Word Highlight Offset Verification

## Problem
In `calculate_highlight_stack`, the Phase 2 (Context Match) index verification logic is strictly comparing the `data.index` (which represents the start of the card/selection) with the `target_l_idx` of the current token. 

For multi-word phrases, only the first token (offset 0) matches this index. Continuation words (offsets 1, 2, etc.) fail the check because their logical indices are shifted. This causes them to fall back to Phase 3 (Split Matching), which colors them purple and prevents them from participating in strict sequence matching across different subtitle records.

## Proposed Solution
Refactor the index check at line 865 of `scripts/lls_core.lua` to account for the word's offset within the term. The expected index for a token should be `data.index + (term_offset - 1)`.

By making this check offset-aware, all words in a contiguous phrase will correctly validate against the exported anchor, maintaining "Sequence Match" (Orange) status and respecting the `anki_global_highlight` settings correctly for the entire phrase.

## Impact
- **Consistency**: Multi-word phrases will highlight in a single, consistent color (Orange) rather than a mix of Orange and Purple.
- **Accuracy**: "Bleed" prevention logic will be enforced correctly for the entire phrase, as each word will now correctly identify whether it belongs to the specific exported instance.
- **Visuals**: Eliminates confusing purple coloring for words that were clearly part of the intended selection.
