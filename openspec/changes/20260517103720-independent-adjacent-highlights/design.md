## Context

In `kardenwort-mpv`, mined highlights are parsed from a local TSV database and loaded into memory (`FSM.ANKI_HIGHLIGHTS`). During viewport rendering, `calculate_highlight_stack` evaluates the loaded highlights against active subtitle tokens.

For subtitle streams that lack traditional sentence boundaries and punctuation (e.g., YouTube auto-subtitles), the user may highlight identical or adjacent identical phrase fragments. Previously, highlight matching (`matched_terms`) and split-match index caching (`subs[sub_idx].__split_valid_indices`) were keyed solely by raw `term` text. When multiple distinct TSV records contained the same term, their tracking states collided, preventing the second highlight from rendering.

## Goals / Non-Goals

**Goals:**
- Uniquely identify each parsed or dynamically added highlight record in memory using an identity key (`__entry_key`).
- Key the deduplication tracking and split-match caching by `__entry_key` instead of raw `term`.
- Ensure adjacent identical highlight occurrences render independently in the OSD and stay properly cached.
- Preserve 100% backward compatibility and file system compatibility (no change to the physical TSV database schema).

**Non-Goals:**
- Storing the unique entry keys physically in the TSV file (they must remain in-memory and dynamically generated).
- Altering the core search or pivot-based grounding algorithms.

## Decisions

### 1. In-Memory Identity Key (`__entry_key`) Generation
- **Decision**: Concatenate `term`, `context`, standard-formatted `time`, `index`, and a sequential `row_id` counter using a pipe (`|`) delimiter.
- **Rationale**: Since Lua lacks standard UUID libraries, a deterministic concatenation of the record's primary fields combined with a sequential row index guarantees uniqueness, robustness under loading/saving operations, and zero extra runtime dependencies.
- **Alternatives Considered**: Keying strictly on `row_id`. However, if rows are sorted or modified in memory, a plain integer ID might clash. Concatenating attributes ensures a strong, self-describing cryptographic-like identifier.

### 2. Identity-Key Caching in the Split-Match Cache
- **Decision**: Key the subtitle's cache `subs[sub_idx].__split_valid_indices` by `__entry_key` instead of raw `term`.
- **Rationale**: This separates the caching space for identical phrases in the same subtitle segment, preventing one row's match validation from wiping out or incorrectly overriding another row's.

## Risks / Trade-offs

- **[Risk]** Newly saved highlights mismatch in structure or key format.
  - *Mitigation*: Update `save_anki_tsv_row` to generate the matching `__entry_key` dynamically using `#FSM.ANKI_HIGHLIGHTS + 1` as the sequential ID before inserting it into the in-memory array.
