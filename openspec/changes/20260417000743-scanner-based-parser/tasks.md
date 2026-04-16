## 1. Preparation

- [ ] 1.1 Backup the existing `build_word_list` and `compose_term_smart` in `lls_core.lua` (around L412).
- [ ] 1.2 Research or confirm the most efficient byte-skipping method for UTF-8 in Lua 5.1/mpv (e.g., using `utf8.codes` if available).

## 2. Implement Scanner Core

- [ ] 2.1 Implement `is_word_char(c)` function that returns true for alphanumeric ASCII + German characters (`äöüßÄÖÜ`).
- [ ] 2.2 Implement the `while` loop scanner to atomize tokens:
    - [ ] Handle `{...}` as a single `TAG` token.
    - [ ] Handle `[...]` as a single `METADATA` token.
    - [ ] Handle contiguous word characters as a single `WORD` token.
    - [ ] Handle everything else as a single `SEPARATOR` token.
- [ ] 2.3 Ensure every character of the input string is accounted for in the output token list.

## 3. Refactor Joins and Stripping

- [ ] 3.1 Refactor `compose_term_smart` to handle the clean stream (ensuring spaces are only added between certain types of tokens).
- [ ] 3.2 Verify that `anki_strip_metadata` logic still functions correctly with the new `METADATA` tokens.

## 4. Verification

- [ ] 4.1 Test tokenization of German compounds with hyphens (`Donaudampf-Schiff`).
- [ ] 4.2 Test tokenization of metadata brackets at the start of subtitles (`[Music]`).
- [ ] 4.3 Test highlight targeting via Drum Window selection to ensure word indexing is stable.
- [ ] 4.4 Verify Anki export still produces the correct term and context.
