## Context

The Drum Window allows users to Ctrl+LMB-click individual words across different subtitle lines to accumulate a pending set, then Ctrl+MMB-click to commit those words as a combined Anki flashcard term.

`ctrl_commit_set` (in `lls_core.lua`) gathers context lines anchored on the single MMB-clicked line (`line_idx ± anki_context_lines`). It then calls `extract_anki_context(full_ctx_text, term, ...)` which relies on a `full_lower:find(term_lower)` substring search to locate the term within the context block.

**Bug 1 — wrong window anchor**: when selected words come from different subtitle lines the context window around the MMB line may not cover all contributing lines, so the composed term is absent from the block. The search misses, `extract_anki_context` falls back to returning the full raw blob, and unrelated text ends up in the TSV context field.

**Bug 2 — non-contiguous term verbatim search failure**: even after Bug 1 is fixed, `extract_anki_context` tries to find the composed term as a verbatim substring (e.g. `"ist die Anwohner"`). A non-contiguous selection deliberately skips words between the picks (actual subtitle text: `"ist für die Anwohner"`), so the verbatim search always returns nil for such terms regardless of how wide the context window is. When `start_pos` is nil the function returns `sentence = full_line` (the entire raw blob), which begins at whatever line started the context window — completely wrong.

## Goals / Non-Goals

**Goals:**
- Ensure the context window passed to `extract_anki_context` always spans at least from the earliest-member line to the latest-member line, so all contributing subtitle text is present in the block.
- Handle non-contiguous terms that cannot be found verbatim in `extract_anki_context` by using a center-proximity search for all words in the term, anchoring on the match closest to the selection midpoint.
- Use `time_pos` of the FIRST (document-earliest) member line as the export timestamp, consistent with where the selection begins.
- Keep both fixes minimal and surgical — no new abstractions or API changes.

**Non-Goals:**
- Rewriting `extract_anki_context` beyond the one-fallback addition.
- Changing how the term string is composed (word ordering, joining, punctuation stripping).
- Any visual/rendering changes.

## Decisions

### Decision 1: Anchor context on `[first_member.line … last_member.line]` with `anki_context_lines` padding on each side

**Chosen**: Replace `ctx_start = max(1, line_idx - anki_context_lines)` / `ctx_end = min(#subs, line_idx + anki_context_lines)` with:
```
ctx_start = max(1,     members[1].line    - Options.anki_context_lines)
ctx_end   = min(#subs, members[#members].line + Options.anki_context_lines)
```
After `table.sort(members, ...)` (which already runs just above), `members[1]` is the document-earliest word and `members[#members]` is the latest.

**Rationale**: This guarantees the window always contains all contributing lines. Since the words are sorted by the existing sort block, the first/last indices are already available with zero extra work. The padding (`anki_context_lines`) is kept to preserve surrounding sentence context.

**Alternative considered**: Expand the existing single-anchor window until the term appears in it. Rejected — fragile, harder to reason about, and more code.

### Decision 2: Set `time_pos = subs[members[1].line].start_time`

Replace `time_pos = sub.start_time` (where `sub = subs[line_idx]` = the MMB line) with `time_pos = subs[members[1].line].start_time`.

**Rationale**: The natural "start" of a selection is its first word in document order. Using the MMB-commit line's time is arbitrary and depends on where the user happens to click to commit, which is inconsistent.

### Decision 3: Center-proximity word anchor in `extract_anki_context`

**Chosen**: When verbatim `find(term_lower)` fails, implement a proximity-aware search:
1. Calculate the `center` of the context blob.
2. Iterate through every word in the composed term.
3. For each word, find all occurrences in the context blob.
4. Calculate the distance from each occurrence's midpoint to the blob's center.
5. Anchor the sentence boundary search on the occurrence with the minimum distance (`best_dist`).

**Rationale**: Composed terms for multi-word selections are often non-contiguous, meaning a verbatim substring search fails. While anchoring on the first word is better than failing, it breaks if the first word is a common word (e.g., "und") appearing elsewhere in the context padding. Since the context blob is built symmetrically around the selection, the "correct" occurrence of any word in the term is statistically guaranteed to be the one closest to the center of the blob.

**Alternative considered**: Naive first-word anchor. Rejected because it incorrectly anchors on earlier sentences if the selection starts with a common word.

## Risks / Trade-offs

- **[Risk] Context window may grow large for widely-spaced picks** → Mitigation: `anki_context_lines` acts as padding; the `effective_limit` word-count guard already exists downstream to truncate oversized contexts.
- **[Risk] `members[1]` lookup assumes sort already ran** → Mitigation: The sort block runs unconditionally before this code in the same function.
- **[Risk] First word is ambiguous (appears in multiple sentences in the context blob)** → Mitigation: Because the context window now correctly spans the selected lines (Decision 1), the first occurrence of the first word in the blob will be in a sentence that overlaps the selection — mitigating most false matches.

## Migration Plan

Two surgical patches in `scripts/lls_core.lua`:
1. `ctrl_commit_set` (~line 1958): widen context window anchor.
2. `extract_anki_context` (~line 737): add first-word fallback block.

No schema, config, or API changes. No rollback required.

## Open Questions

*(none)*
