## 1. Fix `ctrl_commit_set` Context Window

- [x] 1.1 In `ctrl_commit_set` (after `table.sort(members, ...)`), replace the single-line-anchored context variables `ctx_start`/`ctx_end` (currently based on `line_idx`) with a span from `members[1].line` to `members[#members].line`, each padded by `Options.anki_context_lines` on the outside
- [x] 1.2 Replace `time_pos = sub.start_time` (where `sub = subs[line_idx]`) with `time_pos = subs[members[1].line].start_time` to timestamp from the earliest selected word
- [x] 1.3 Remove the now-redundant `local sub = subs[line_idx]` / `if not sub then return end` guard block that exists only to anchor the old single-line context — guard is no longer needed since both member lines are already validated when words are composed above

## 2. Fix `extract_anki_context` Non-Contiguous Fallback

- [x] 2.1 Refine `extract_anki_context` with a center-proximity fallback: Instead of a naive verbatim search, iterate through term words and anchor on the occurrence closest to the blob center. This handles non-contiguous terms and avoids ambiguity from common words (like "und").

## 3. Verification

- [ ] 3.1 Export a same-line multi-word set (verbatim match) -> Confirm context OK.
- [ ] 3.2 Export a different-line multi-word set (broken verbatim) -> Confirm context spans lines.
- [ ] 3.3 Export a non-contiguous set (skipped words, e.g., "ist die Anwohner") -> Confirm correct sentence.
- [ ] 3.4 Export a selection starting with a common word (e.g., "und Ende") where "und" appears earlier in the padding -> Confirm it correctly anchors on the selection's "und" and not the earlier one.
- [ ] 3.5 Check TSV output reproduces all reported bug scenarios.
