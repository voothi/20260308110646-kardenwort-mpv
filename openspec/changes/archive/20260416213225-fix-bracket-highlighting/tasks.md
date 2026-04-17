## 1. Export & Selection
- [x] 1.1 Update `build_word_list` to strip ASS tags `{[^}]+}` and split by `[/-]`, `–`, `—`.
- [x] 1.2 Update `dw_osd:update` to join words without spaces when adjacent to hyphen/slash/dash tokens.
- [x] 1.3 Update `dw_anki_export_selection` and `ctrl_commit_set` to robustly strip brackets from specifically selected tags.

## 2. Highlighting
- [x] 2.1 Update `calculate_highlight_stack` to strip ASS tags and support the new dash characters.
- [x] 2.2 Update `calculate_highlight_stack` to bypass neighbor strictness check for bracketed words AND units like (ca, km, cm, mm).

## 3. Verification
- [x] 3.1 Verify that `ca` and `km` highlight even in new contexts.
- [x] 3.2 Verify that `20–25` (with en-dash) is splittable and matches cards.
- [x] 3.3 Verify that `[UMGEBUNG]` highlights globally.
- [x] 3.4 Verify that ASS tags in subtitles don't break highlighting.
