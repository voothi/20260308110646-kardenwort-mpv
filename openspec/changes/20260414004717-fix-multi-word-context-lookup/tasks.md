## 1. Fix `ctrl_commit_set` Context Window

- [x] 1.1 In `ctrl_commit_set` (after `table.sort(members, ...)`), replace the single-line-anchored context variables `ctx_start`/`ctx_end` (currently based on `line_idx`) with a span from `members[1].line` to `members[#members].line`, each padded by `Options.anki_context_lines` on the outside
- [x] 1.2 Replace `time_pos = sub.start_time` (where `sub = subs[line_idx]`) with `time_pos = subs[members[1].line].start_time` to timestamp from the earliest selected word
- [x] 1.3 Remove the now-redundant `local sub = subs[line_idx]` / `if not sub then return end` guard block that exists only to anchor the old single-line context — guard is no longer needed since both member lines are already validated when words are composed above

## 2. Verification

- [ ] 2.1 Export a multi-word set where the words come from the **same** subtitle line — confirm context and timestamp are unchanged/correct
- [ ] 2.2 Export a multi-word set where the words come from **different** subtitle lines — confirm the context now includes all contributing lines and the term is found verbatim within it
- [ ] 2.3 Check the TSV output matches the visible text shown in the Drum Window for a cross-line multi-word export (reproduces the reported bug scenario with `"für vielfältiges Schnupperkursen"`)
