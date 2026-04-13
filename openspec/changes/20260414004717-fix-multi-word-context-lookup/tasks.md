## 1. Fix `ctrl_commit_set` Context Window

- [x] 1.1 In `ctrl_commit_set` (after `table.sort(members, ...)`), replace the single-line-anchored context variables `ctx_start`/`ctx_end` (currently based on `line_idx`) with a span from `members[1].line` to `members[#members].line`, each padded by `Options.anki_context_lines` on the outside
- [x] 1.2 Replace `time_pos = sub.start_time` (where `sub = subs[line_idx]`) with `time_pos = subs[members[1].line].start_time` to timestamp from the earliest selected word
- [x] 1.3 Remove the now-redundant `local sub = subs[line_idx]` / `if not sub then return end` guard block that exists only to anchor the old single-line context — guard is no longer needed since both member lines are already validated when words are composed above

## 2. Fix `extract_anki_context` Non-Contiguous Fallback

- [x] 2.1 After `full_lower:find(term_lower, 1, true)` in `extract_anki_context`, add a first-word fallback: when `start_pos` is nil, extract the first whitespace-delimited word of `term_lower` and search for it in `full_lower`; use the result as `start_pos`/`end_pos` so the existing sentence boundary logic runs correctly

## 3. Verification

- [ ] 3.1 Export a multi-word set where words come from the **same** subtitle line — confirm context and timestamp are correct
- [ ] 3.2 Export a multi-word set where words come from **different** subtitle lines — confirm context spans both lines and term is locatable
- [ ] 3.3 Export a **non-contiguous** selection (words with skipped words between them, e.g. `"ist die Anwohner"` skipping `"für"`) — confirm context now matches the correct sentence from the Drum Window
- [ ] 3.4 Check TSV output reproduces the reported bug scenarios (`"für vielfältiges Schnupperkursen"` and `"ist die Anwohner"`)
