## 1. Refactor Global Split Matching (Phase 3)

- [ ] 1.1 In `calculate_highlight_stack`, update Phase 3 initialization to use `sub_idx` as the center if `anki_global_highlight` is true.
- [ ] 1.2 Bypass the `gap < anki_split_gap_limit` check against `data.time` when Global mode is active, ensuring `ctx_list` is populated for segments local to the current playback.
- [ ] 1.3 Verify that the inter-constituent temporal gap check remains functional to avoid spurious phrase matches.

## 2. Harden Global Context Verification (Phase 2)

- [ ] 2.1 Refactor the neighborhood check in Phase 2 of `calculate_highlight_stack`.
- [ ] 2.2 Transition from literal `find` on the whole segment text to a word-token intersection check.
- [ ] 2.3 Ensure the tokenization ignores standard punctuation and tiny symbols to maximize recall while maintaining context precision.

## 3. Verification & Regression Testing

- [ ] 3.1 Verify high-recall highlighting for common words (like "die") in Global Mode even with punctuation mismatches between TSV and movie.
- [ ] 3.2 Confirm that multi-word phrases (like "41 bis 45") are highlighted across the entire timeline in Global Mode.
- [ ] 3.3 Perform regression testing for Global OFF mode, ensuring that "Index Grounding" still strictly isolates highlights to their original source segments.
