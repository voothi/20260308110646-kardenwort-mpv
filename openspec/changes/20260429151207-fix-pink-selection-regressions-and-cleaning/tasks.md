## 1. Unified Shared Logic

- [x] 1.1 Create `clean_anki_term(term)` in `lls_core.lua` to encapsulate tag/metadata stripping.
- [x] 1.2 Update `dw_anki_export_selection` to use `clean_anki_term`.

## 2. Fix Yellow Selection Regression (Dangling Parenthesis)

- [x] 2.1 Implement "End of Line" guard in `dw_anki_export_selection` trailing token loop.
- [x] 2.2 Add punctuation filter to exclude opening characters (`(`, `[`) from trailing capture.

## 3. Refactor Pink Selection (Paired Export)

- [x] 3.1 Integrate `clean_anki_term` into `ctrl_commit_set`.
- [x] 3.2 Implement multi-pass lookahead for literal terminal punctuation (skipping metadata).
- [x] 3.3 Replace manual concatenation with `compose_term_smart` for non-gap word joining.

## 4. Verification

- [ ] 4.1 **Test Yellow Boundary**: Select `Gruppe` in `Gruppe (Neutraubling)`. Verify exported term is `Gruppe` (no dangling paren).
- [ ] 4.2 **Test Pink Cleaning**: Select words around `[METADATA]`. Verify term is cleaned.
- [ ] 4.3 **Test Pink Punctuation**: Select last word of `Test!`. Verify term is `... Test!`.
- [ ] 4.4 **Test Pink Metadata Bypass**: Select last word of `Test [METADATA]?`. Verify term is `... Test?`.
