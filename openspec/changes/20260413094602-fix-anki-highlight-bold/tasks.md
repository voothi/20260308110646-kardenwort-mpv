## 1. Refactor word highlighting logic

- [ ] 1.1 Implement the `format_highlighted_word` helper function in `scripts/lls_core.lua`.
- [ ] 1.2 Include the `anki_highlight_bold` logic (wrapping in `{\b1}`/`{\b0}`) in the helper function.
- [ ] 1.3 Refactor the classic `draw_drum` renderer function to use the new helper.
- [ ] 1.4 Refactor the unified `draw_dw` (Drum Window) renderer function to use the new helper.

## 2. Verification and testing

- [ ] 2.1 Verify that bolding works correctly in the Drum Window when `lls-anki_highlight_bold=yes` is set in `mpv.conf`.
- [ ] 2.2 Verify that the classic Drum Mode still correctly handles bolding for both active and context lines.
- [ ] 2.3 Verify that "Surgical Highlighting" (unbolded/uncolored punctuation) still works for single-word matches.
- [ ] 2.4 Verify that "Phrase Continuity Mode" (bolded/colored punctuation) still works for multi-word matches.
- [ ] 2.5 Verify that disabling `lls-anki_highlight_bold` removes all extra bolding as expected.
