# Tasks: Phrase Highlighting Precision

## 1. Analysis and Preparation

- [ ] 1.1 Locate `calculate_highlight_stack` in `scripts/lls_core.lua` and identify the phrase search window logic.
- [ ] 1.2 Identify where `needs_strict` is calculated and how it interacts with `term_clean` length.

## 2. Core Implementation

- [ ] 2.1 Modify `needs_strict` calculation to ensure phrases respect logical index targeting when global mode is disabled.
- [ ] 2.2 Update the phrase matching loop to verify the absolute `logical_index` if it's available in the triggering `data` object.
- [ ] 2.3 Ensure that the expanded +/- 15 line window only acts as a search range, not as a "match everything" range.

## 3. Verification and Polish

- [ ] 3.1 Test with a subtitle track containing repeating multi-word phrases (like the user's "41 bis 45").
- [ ] 3.2 Verify that `lls-anki_global_highlight=no` correctly isolates the selection to a single row.
- [ ] 3.3 Verify that `lls-anki_global_highlight=yes` still highlights all occurrences as expected.
- [ ] 3.4 (Optional) Add a comment to the default `mpv.conf` or documentation regarding `anki_context_strict=yes`.
