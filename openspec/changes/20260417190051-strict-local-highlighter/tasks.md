## 1. Configuration

- [x] 1.1 Update `Options.anki_local_fuzzy_window` default from `10.0` to `2.0` in `scripts/lls_core.lua`.

## 2. Highlighter Logic Refactoring

- [x] 2.1 Modify the `window` variable calculation in `calculate_highlight_stack` to skip the expansion logic when `Options.anki_global_highlight` is `false`.
- [x] 2.2 Implement a conditional subtitle scan range in `calculate_highlight_stack`. If `anki_global_highlight` is `false`, use a range of ±3 subtitles instead of ±15 for multi-word term validation.
- [x] 2.3 Ensure the `in_window` flag correctly evaluates the tighter 2s window for single words in local mode.

## 3. Testing and Verification

- [ ] 3.1 Load the provided TSV and visually verify that "die" (from 18s) no longer appears in the subtitle at 28s when Global Highlight is OFF.
- [ ] 3.2 Verify that "Aufgaben 41" (from 28s) no longer appears in the 47s subtitle cluster when Global Highlight is OFF.
- [ ] 3.3 Toggle Global Highlight ON and verify that high-recall (broad windows) still functions as expected.
