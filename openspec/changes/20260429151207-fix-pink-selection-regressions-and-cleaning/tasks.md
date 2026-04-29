## 1. Preparation and Shared Logic

- [ ] 1.1 Create a shared helper function `clean_anki_term(term)` in `lls_core.lua` to encapsulate all term cleaning logic.
- [ ] 1.2 Migrate existing cleaning logic from `dw_anki_export_selection` into `clean_anki_term`.
- [ ] 1.3 Verify that Yellow selection export still works correctly after the refactor.

## 2. Refactoring Pink Selection Export

- [ ] 2.1 Update the token lookahead in `ctrl_commit_set` to skip metadata tokens when searching for trailing punctuation.
- [ ] 2.2 Modify the punctuation detection to capture the literal token text instead of just setting a boolean flag.
- [ ] 2.3 Integrate `clean_anki_term` into the Pink export path before final restoration.
- [ ] 2.4 Replace manual string concatenation in `ctrl_commit_set` with `compose_term_smart` for non-gap word joining.

## 3. Verification

- [ ] 3.1 Verify that `Paketsortierung. [UMGEBUNG]` correctly restores the period in Pink mode.
- [ ] 3.2 Verify that `!`, `?`, and `...` are correctly preserved for Pink selections.
- [ ] 3.3 Verify that metadata tags inside a paired selection are correctly stripped from the term.
