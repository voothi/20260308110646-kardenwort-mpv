## 1. Export & Selection
- [ ] 1.1 Update `build_word_list` to split tokens by `-` and `/` while preserving them as separate tokens.
- [ ] 1.2 Update `dw_osd:update` to join words without spaces when adjacent to `-` or `/` tokens.
- [ ] 1.3 Update `dw_anki_export_selection` and `ctrl_commit_set` to robustly strip brackets from specifically selected tags.

## 2. Highlighting
- [ ] 2.1 Update `calculate_highlight_stack` to bypass neighbor strictness check for bracketed words (e.g. `[UMGEBUNG]`).
- [ ] 2.2 Re-verify metadata neighbor tolerance (Task 2.1 from previous attempt).

## 3. Verification
- [ ] 3.1 Verify that `[UMGEBUNG]` highlights globally (ignoring neighbors).
- [ ] 3.2 Verify that `Netto` can be added independently from `Netto/Globus` by clicking it.
- [ ] 3.3 Verify that `Netto/Globus` still highlights as a phrase card.
- [ ] 3.4 Verify that `[UMGEBUNG]` is saved as `UMGEBUNG`.
