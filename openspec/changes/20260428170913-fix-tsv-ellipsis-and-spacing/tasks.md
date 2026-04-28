# Tasks: Fix TSV Ellipsis and Spacing Logic

## 1. Core Logic Refactoring

- [ ] 1.1 Update `compose_term_smart` in `scripts/lls_core.lua` to prevent redundant space injection if tokens already contain whitespace at boundaries.
- [ ] 1.2 Update `ctrl_commit_set` in `scripts/lls_core.lua` to inject the space-padded ellipsis `" ... "` instead of `"..."`.

## 2. Verification

- [ ] 2.1 Verify that non-contiguous selections (e.g., "she's" and "putting") now export as "she's ... putting" in TSV.
- [ ] 2.2 Verify that multi-word contiguous selections with original spacing (e.g., "find   those") no longer have extra spaces injected by the joiner.
- [ ] 2.3 Verify that hyphens and other non-spacing punctuation still join correctly (e.g., "Marken-Discount").
