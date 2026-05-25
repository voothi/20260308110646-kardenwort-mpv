## 1. Option plumbing

- [ ] 1.1 Add `anki_abbrev_list` to the `Options` table in `scripts/kardenwort/main.lua` with default value `"z.B.,bzw.,usw.,ca.,d.h.,u.a.,etc.,vgl.,ggf.,bspw.,u.U.,i.d.R.,bzgl.,evtl."`.
- [ ] 1.2 Add the option to `read_options` so `script-opts=kardenwort-anki_abbrev_list=...` in `mpv.conf` overrides the default.
- [ ] 1.3 Parse the comma-separated string once at load time into a lowercase-keyed lookup table (e.g. `Options._anki_abbrev_set`).

## 2. Shared abbreviation helper

- [ ] 2.1 Extract a module-local function `is_abbreviation(token)` that takes a token (string including any trailing period) and returns `true` if it matches the existing heuristic OR appears in `Options._anki_abbrev_set` (case-insensitive).
- [ ] 2.2 Ensure the heuristic covers: 1–4 lowercase letters + `.` (e.g. `ca.`, `usw.`, `bzw.`, `d.h.`); single-uppercase-letter+`.` segments concatenated (e.g. `z.B.`, `T.CON`).
- [ ] 2.3 Replace inline abbreviation logic in `dw_anki_export_selection`'s `is_sentence_boundary` evaluation with a call to `is_abbreviation`.

## 3. Sentence scoping rewrite in `extract_anki_context`

- [ ] 3.1 In `scripts/kardenwort/main.lua` around lines 2897–2921, replace the existing backward/forward `\0` searches with a backward terminator scan: walking `full_line` from `start_pos - 1` toward index 1, find the nearest `[.!?]` whose look-ahead (next non-`%s%z` char) is whitespace, NUL, end-of-string, OR a capital letter; AND whose preceding token (read backward to the previous whitespace/`\0`/start) is NOT classified as an abbreviation.
- [ ] 3.2 Implement the symmetric forward terminator scan from `end_pos + 1` toward `#full_line`. Include the terminator character in the captured range (i.e. `sent_end` advances past the matched `.`/`!`/`?`).
- [ ] 3.3 Compute `raw_sub = full_line:sub(sent_start, sent_end)` then replace `\0` with space and trim, identical to the current post-processing; preserve the `sentence_abs_start` calculation so downstream offset math (lines 2929-3017) is unaffected.
- [ ] 3.4 If neither scan finds a real terminator, set `sent_start = 1` and `sent_end = #full_line` so the entire joined block becomes the sentence (No-Terminator Fallback).
- [ ] 3.5 Preserve all existing diagnostic `print` / `Diagnostic.trace` output formats so logs remain readable; add a one-line trace describing which terminator was hit on each side (or "fallback: full block").

## 4. Acceptance tests

- [ ] 4.1 Add a Python acceptance test `tests/acceptance/test_20260525193414_period_sentence_scoping.py` that constructs a context block of three subtitle lines (`"Es kommt zu kräftigen Niederschlägen,"`, `"die verbreitet als Schnee liegen"`, `"bleiben. Autofahrer sollten besonders"`) joined by `\0`, calls `extract_anki_context` (via the existing Lua test harness), and asserts the result for the selection `"verbreitet"` equals `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."`
- [ ] 4.2 Add a test for non-contiguous span `"Autofahrer ... rechnen"` across `"bleiben. Autofahrer sollten besonders"`, `"auf den Autobahnen im Süden mit glatten"`, `"Straßen rechnen."` — assert the result starts with `"Autofahrer"` (not `"bleiben."`) and ends with `"rechnen."`.
- [ ] 4.3 Add a test for the abbreviation skip with `"Es liegt ca. 97 km von Plattling"` — assert `extract_anki_context` for selection `"97"` does NOT split at `"ca."`.
- [ ] 4.4 Add a test for the no-terminator fallback with three unpunctuated subtitle lines — assert the result is the entire joined block (space-separated), not a single line.
- [ ] 4.5 Add a test for the new `anki_abbrev_list` extension: configure list `"Prof."`, feed context `"Prof. Müller sagte das."`, selection `"Müller"`, assert the result includes `"Prof. Müller sagte das."` (not split at `"Prof."`).
- [ ] 4.6 Review the two existing acceptance tests `tests/acceptance/test_20260509085806_anki_context_verbatim.py` and `tests/acceptance/test_20260509102214_spec_depth_pass2.py` for fixtures that assume single-subtitle-line scoping; update assertions to match the new (correct) full-sentence behaviour, or document them as covering a different invariant.

## 5. Documentation

- [ ] 5.1 Add the new `anki_abbrev_list` option to any consumption-focused docs (look for entries about `anki_context_max_words` / `anki_context_lines` and place the new option near them).
- [ ] 5.2 Add a short note in `CHANGELOG.md` (if present) or the project README describing the regression fix and the new option.

## 6. Verification

- [ ] 6.1 Re-export the words `verbreitet`, `glatten`, `wichtige Suchmeldung`, `Autofahrer ... rechnen` from the user's `20260412001656-hoeren-b2-telc-uebungstest` SRT and visually verify the `SentenceSource` column contains full sentences matching the proposal's expected-output table.
- [ ] 6.2 Verify a YouTube auto-subtitle export (no punctuation) still produces a non-empty multi-line `SentenceSource` (the full ±N joined block).
- [ ] 6.3 Verify that exports of selections that include an abbreviation (`ca.`, `z.B.`) at the sentence start/end still produce the correct full sentence without truncation.
- [ ] 6.4 Run `openspec validate 20260525193414-restore-period-sentence-scoping` and confirm zero errors.

## 7. Archive

- [ ] 7.1 After all acceptance tests pass and verification scenarios are confirmed visually, run `openspec archive 20260525193414-restore-period-sentence-scoping` so the `specs/subtitle-aware-sentence-extraction/spec.md` and `specs/adaptive-context-truncation/spec.md` files are updated with the new merged content.
