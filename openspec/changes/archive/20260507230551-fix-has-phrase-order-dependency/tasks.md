## 1. Code fix

- [x] 1.1 In `scripts/lls_core.lua` line 2296, change `has_phrase = (#term_clean > 1)` to `has_phrase = has_phrase or (#term_clean > 1)`. <!-- id: 0 -->

## 2. Spec update

- [x] 2.1 Update `openspec/specs/anki-highlighting/spec.md` to add an order-invariance scenario under the "Split-Term Multi-Word Highlighting" requirement: `has_phrase` MUST reflect any multi-word match in the candidate set, regardless of TSV record ordering. <!-- id: 1 -->

## 3. Verification

- [x] 3.1 Manual test — TSV order A (single-word records before phrase record): confirm words belonging to the phrase term receive full-word backlight, not surgical. <!-- id: 2 -->
- [x] 3.2 Manual test — TSV order B (phrase record before single-word records): confirm identical visual output to order A. <!-- id: 3 -->
- [x] 3.3 Verify surgical highlighting still applies correctly for words matched only by single-word records (no phrase term involved). <!-- id: 4 -->
