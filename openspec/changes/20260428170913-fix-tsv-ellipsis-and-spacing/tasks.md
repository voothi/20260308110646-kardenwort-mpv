# Tasks: Fix TSV Ellipsis and Spacing Logic

## 1. Core Logic Refactoring

- [ ] 1.1 Update `compose_term_smart` in `scripts/lls_core.lua` to enforce strict single-space normalization by collapsing all whitespace tokens and preventing redundant injection.
- [ ] 1.2 Update `ctrl_commit_set` in `scripts/lls_core.lua` to inject the space-padded ellipsis `" ... "` instead of `"..."`.

## 2. Verification

- [ ] 2.1 Verify that non-contiguous selections (e.g., "she's" and "putting") now export as "she's ... putting" in TSV.
- [ ] 2.2 Verify that multi-word contiguous selections with original spacing (e.g., "find   those") now have all intermediate whitespace collapsed to a single space ("find those").
- [ ] 2.3 Verify that hyphens and other non-spacing punctuation still join correctly (e.g., "Marken-Discount").
