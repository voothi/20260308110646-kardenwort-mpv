## 1. Option plumbing

- [x] 1.1 Add `anki_abbrev_list` to the `Options` table in `scripts/kardenwort/main.lua` with default value `"z.B.,bzw.,usw.,ca.,d.h.,u.a.,etc.,vgl.,ggf.,bspw.,u.U.,i.d.R.,bzgl.,evtl."`.
- [x] 1.2 Add the option to `read_options` so `script-opts=kardenwort-anki_abbrev_list=...` in `mpv.conf` overrides the default.
- [x] 1.3 Parse the comma-separated string once at load time into a lowercase-keyed lookup table (e.g. `Options._anki_abbrev_set`). (Existing `is_abbrev` performs space-separated linear search; adequate for list size.)
- [x] 1.4 Add `anki_sentence_terminators` to `Options` with default value `".!?"` (plain string of characters, no separator).
- [x] 1.5 Add `anki_sentence_terminators` to `read_options` so it can be overridden via `mpv.conf`.
- [x] 1.6 After loading, build a Lua character class pattern string from `anki_sentence_terminators` (e.g. `"[%.!%?]"` for the default) stored in `Options._sentence_term_pattern`; fall back to `"[%.!%?]"` if the option is empty. (Implemented as inline `is_terminator_char` helper; avoids need for precomputed derived state.)

## 2. Shared abbreviation helper

- [x] 2.1 Extract a module-local function `is_abbreviation(token)` that takes a token (string including any trailing period) and returns `true` if it matches the existing heuristic OR appears in `Options._anki_abbrev_set` (case-insensitive). (Existing `is_abbrev` function serves this role; added `token_ending_at` and `is_terminator_char` helpers.)
- [x] 2.2 Ensure the heuristic covers: 1–4 lowercase letters + `.` (e.g. `ca.`, `usw.`, `bzw.`, `d.h.`); single-uppercase-letter+`.` segments concatenated (e.g. `z.B.`, `T.CON`). (Verified: heuristic handles each segment; full tokens covered by `anki_abbrev_list`.)
- [x] 2.3 Replace inline abbreviation logic in `dw_anki_export_selection`'s `is_sentence_boundary` evaluation with a call to `is_abbreviation`. (No inline abbreviation logic present; `is_sentence_boundary` is a dead variable from the prior archived change — no action needed.)

## 3. Sentence scoping rewrite in `extract_anki_context`

- [x] 3.1 In `scripts/kardenwort/main.lua` around lines 2897–2921, replace the existing backward/forward `\0` searches with a backward terminator scan: walking `full_line` from `start_pos - 1` toward index 1, find the nearest character matching `Options._sentence_term_pattern` whose look-ahead (next non-`%s%z` char) is whitespace, NUL, end-of-string, OR a capital letter; AND whose preceding token (read backward to the previous whitespace/`\0`/start) is NOT classified as an abbreviation.
- [x] 3.2 Implement the symmetric forward terminator scan from `end_pos + 1` toward `#full_line`. Include the terminator character in the captured range (i.e. `sent_end` advances past the matched `.`/`!`/`?`).
- [x] 3.3 Compute `raw_sub = full_line:sub(sent_start, sent_end)` then replace `\0` with space and trim, identical to the current post-processing; preserve the `sentence_abs_start` calculation so downstream offset math (lines 2929-3017) is unaffected.
- [x] 3.4 If neither scan finds a real terminator, set `sent_start = 1` and `sent_end = #full_line` so the entire joined block becomes the sentence (No-Terminator Fallback).
- [x] 3.5 Preserve all existing diagnostic `print` / `Diagnostic.trace` output formats so logs remain readable; add a one-line trace describing which terminator was hit on each side (or "fallback: full block").

## 4. Acceptance tests

- [x] 4.1 Add a Python acceptance test `tests/acceptance/test_20260525193414_period_sentence_scoping.py` that constructs a context block of three subtitle lines (`"Es kommt zu kräftigen Niederschlägen,"`, `"die verbreitet als Schnee liegen"`, `"bleiben. Autofahrer sollten besonders"`) joined by `\0`, calls `extract_anki_context` (via the existing Lua test harness), and asserts the result for the selection `"verbreitet"` equals `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."`
- [x] 4.2 Add a test for non-contiguous span `"Autofahrer ... rechnen"` across `"bleiben. Autofahrer sollten besonders"`, `"auf den Autobahnen im Süden mit glatten"`, `"Straßen rechnen."` — assert the result starts with `"Autofahrer"` (not `"bleiben."`) and ends with `"rechnen."`.
- [x] 4.3 Add a test for the abbreviation skip with `"Es liegt ca. 97 km von Plattling"` — assert `extract_anki_context` for selection `"97"` does NOT split at `"ca."`.
- [x] 4.4 Add a test for the no-terminator fallback with three unpunctuated subtitle lines — assert the result is the entire joined block (space-separated), not a single line.
- [x] 4.5 Add a test for the new `anki_abbrev_list` extension: configure list `"Prof."`, feed context `"Prof. Müller sagte das."`, selection `"Müller"`, assert the result includes `"Prof. Müller sagte das."` (not split at `"Prof."`).
- [x] 4.6 Review the two existing acceptance tests `tests/acceptance/test_20260509085806_anki_context_verbatim.py` and `tests/acceptance/test_20260509102214_spec_depth_pass2.py` for fixtures that assume single-subtitle-line scoping; update assertions to match the new (correct) full-sentence behaviour, or document them as covering a different invariant.

## 5. Documentation

- [x] 5.1 Add the new `anki_abbrev_list` option to any consumption-focused docs (look for entries about `anki_context_max_words` / `anki_context_lines` and place the new option near them).
- [x] 5.2 Add a short note in `CHANGELOG.md` (if present) or the project README describing the regression fix and the new option.

## 6. Verification

- [ ] 6.1 Re-export the words `verbreitet`, `glatten`, `wichtige Suchmeldung`, `Autofahrer ... rechnen` from the user's `20260412001656-hoeren-b2-telc-uebungstest` SRT and visually verify the `SentenceSource` column contains full sentences matching the proposal's expected-output table.
- [ ] 6.2 Verify a YouTube auto-subtitle export (no punctuation) still produces a non-empty multi-line `SentenceSource` (the full ±N joined block).
- [ ] 6.3 Verify that exports of selections that include an abbreviation (`ca.`, `z.B.`) at the sentence start/end still produce the correct full sentence without truncation.
- [x] 6.4 Run `openspec validate 20260525193414-restore-period-sentence-scoping` and confirm zero errors.

## 7. Archive

- [ ] 7.1 After all acceptance tests pass and verification scenarios are confirmed visually, run `openspec archive 20260525193414-restore-period-sentence-scoping` so the `specs/subtitle-aware-sentence-extraction/spec.md` and `specs/adaptive-context-truncation/spec.md` files are updated with the new merged content.
