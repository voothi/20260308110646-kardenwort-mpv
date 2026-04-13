## 1. Core Implementation

- [x] 1.1 Implement `starts_with_uppercase` helper in `scripts/lls_core.lua` supporting Latin, German, and Cyrillic.
- [x] 1.2 Modify `extract_anki_context` to handle sentence start boundary detection and period appendage.
- [x] 1.3 Update the main Anki export logic to detect raw terminal punctuation before stripping it from the `term`.
- [x] 1.4 Implement the restoration of terminal punctuation for capitalized `source_word` (term) fields.

## 2. Verification

- [x] 2.1 Verify `source_word` field in TSV correctly receives a period for full-sentence exports.
- [x] 2.2 Verify `source_sentence` (context) field maintains correct punctuation.
- [x] 2.3 Verify lowercase fragments and single words without original terminal punctuation are not modified.
