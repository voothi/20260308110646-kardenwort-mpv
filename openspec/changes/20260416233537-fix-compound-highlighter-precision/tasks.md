## 1. UTF-8 & Language Support

- [x] 1.1 Update `utf8_to_lower` to explicitly handle German umlauts (`ÄÖÜ`) and sharp S (`ß`, `ẞ`).
- [x] 1.2 Update `starts_with_uppercase` to accurately categorize German uppercase characters.

## 2. Highlighter Precision

- [x] 2.1 Implement a robust neighbor search in `calculate_highlight_stack` that skips purely punctuational tokens (up to 3 words distance).
- [x] 2.2 Verify that compound terms like `Marken-Discount` highlight reliably when neighbors are dash-separated.

## 3. Export Data Integrity

- [x] 3.1 Implement `compose_term_smart(tokens)` to join words WITHOUT spaces when adjacent to `-` or `/`.
- [x] 3.2 Update `ctrl_commit_set` and `dw_anki_export_selection` to use `compose_term_smart` for term composition.
- [x] 3.3 Remove per-token punctuation stripping in `ctrl_commit_set` to preserve internal hyphenation and slashes.

## 4. Verification

- [ ] 4.1 Verify `Marken-Discount` export results in "Marken-Discount" in the TSV (no extra spaces).
- [ ] 4.2 Verify `große` highlighting for German cards with `ß`.
- [ ] 4.3 Verify `Netto/Globus` components are selectable and highlight against context.
