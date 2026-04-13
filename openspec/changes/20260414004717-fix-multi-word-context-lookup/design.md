## Context

The Drum Window allows users to Ctrl+LMB-click individual words across different subtitle lines to accumulate a pending set, then Ctrl+MMB-click to commit those words as a combined Anki flashcard term.

`ctrl_commit_set` (in `lls_core.lua`) currently gathers context lines anchored on the single MMB-clicked line (`line_idx ± anki_context_lines`). It then calls `extract_anki_context(full_ctx_text, term, ...)` which relies on a `full_lower:find(term_lower)` substring search to locate the term within the context block.

**The bug**: when selected words come from different subtitle lines (e.g. word from line 5 and word from line 20), the composed term string (e.g. `"für vielfältiges Schnupperkursen"`) never appears verbatim in the narrow context window around one line. The search misses (`start_pos` is nil), `extract_anki_context` falls back to returning the raw full-context string unchanged, and that window contains unrelated content relative to the actual words selected — producing garbage context in the TSV.

## Goals / Non-Goals

**Goals:**
- Ensure the context window passed to `extract_anki_context` always spans at least from the earliest-member line to the latest-member line, so the composed term is guaranteed to be present verbatim in the context.
- Use `time_pos` of the FIRST (document-earliest) member line as the export timestamp, consistent with where the selection begins.
- Keep the fix minimal and surgical — no new abstractions or API changes.

**Non-Goals:**
- Rewriting `extract_anki_context` — the function itself is correct.
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

## Risks / Trade-offs

- **[Risk] Context window may grow large for widely-spaced picks** → Mitigation: `anki_context_lines` acts as padding; the `effective_limit` word-count guard already exists downstream to truncate oversized contexts.
- **[Risk] `members[1]` lookup assumes sort already ran** → Mitigation: The sort block (`table.sort(members, ...)`) is always executed before this new code in the same function, so this assumption is safe.

## Migration Plan

Single-function patch in `scripts/lls_core.lua` around lines 1958–1971. No schema, config, or API changes. No rollback required — the change is mechanical and easily reverted.

## Open Questions

*(none)*
