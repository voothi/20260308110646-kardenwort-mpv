# Tasks: Fix TSV Ellipsis and Spacing Logic

## 1. Core Logic Refactoring

- [x] 1.1 Update `compose_term_smart` in `scripts/lls_core.lua` to enforce strict single-space normalization by collapsing all whitespace tokens and preventing redundant injection (Anchor: 20260428171824).
- [x] 1.2 Update `ctrl_commit_set` in `scripts/lls_core.lua` to inject the space-padded ellipsis `" ... "` instead of `"..."` (Anchor: 20260428165923).
- [x] 1.3 Big model review and syntax verification (Anchor: 20260428172619).

## 2. Verification

- [x] 2.1 Verify that non-contiguous selections (e.g., "she's" and "putting") now export as "she's ... putting" in TSV.
- [x] 2.2 Verify that multi-word contiguous selections with original spacing (e.g., "find   those") now have all intermediate whitespace collapsed to a single space ("find those").
- [x] 2.3 Verify that hyphens and other non-spacing punctuation still join correctly (e.g., "Marken-Discount").
