## Context

The multi-word and split-word highlighting mechanism in the Drum Window relies on matching text from the Anki Word History TSV against currently visible subtitles. Recently, users reported that multi-word terms (both contiguous and non-contiguous) fail to highlight if the time exported in the TSV is outside a hardcoded `anki_local_fuzzy_window` measured against the subtitle's `start_time`. Because `data.time` captures the playback position at the exact moment of export, it can easily deviate from `start_time` by more than the window limit (e.g. at the end of a long subtitle block), causing complete highlights suppression.

Furthermore, sequence matching contained a vulnerability where reaching the end of the subtitle boundary cleanly (`get_relative_word` returning `nil`) would not correctly invalidate a sequence match, potentially risking false-positive highlights. Also, Phase 2 Context matches incorrectly used generic substring matching against `ctx_lower`, which could theoretically match sub-words.

## Goals / Non-Goals

- Fix the false negative rate on Drum Window multi-word highlighting by evaluating fuzzy time matching against the FULL subtitle start-to-end span, not just the start point.
- Eliminate false positive sequence matching when expected contiguous words are missing (`rw == nil`).
- Harden Phase 2 Context matching and split-term identification.
- Robustly handle TSV parsing even when column counts/mappings are inconsistent or truncated.

**Non-Goals:**
- Altering the visual design or colors.
- Affecting single-word highlighting logic unexpectedly.

- **Span-based Time Window:** Update `calculate_highlight_stack` to check `data.time` against `[sub_start - window, sub_end + window]`. This covers long subtitles comprehensively.
- **Strict Boundary Enforcement:** Explicitly set `sequence_match = false` when `get_relative_word` returns `nil`.
- **Fallback Timestamp Parsing:** Implement a backward-scanning logic in `load_anki_highlights` to find valid timestamps in tail columns if the primary `time` mapping fails (e.g., due to row truncation).
- **Shortest-Span Ordered Matching:** For split terms, implement a recursive search that identifies the tightest sequential occurrence of term constituent words in the subtitle context. This prevents generic words (like "die") from triggering false highlights on unrelated instances.
- **Wide-Cluster Spatial Scanning:** Expand subtitle context scan buffer from `[-3, +3]` to `[-15, +15]` chunks (roughly 30-45 seconds of local dialogue) to ensure that widely spread words (e.g. from outer bounds of whole paragraphs) are successfully linked into a valid split occurrence.
- **Symmetric Temporal Sync:** Override the default `anki_local_fuzzy_window` timestamp limit entirely for multi-word phrases, enforcing `data.time` bounds against the extreme limits of the newly defined `[-15, +15]` cluster natively to avoid arbitrary temporal drop-outs for heavily separated pairs (e.g. `Beruf` validating but `da` failing).

## Risks / Trade-offs

- The broader time span match logic might theoretically cross over tightly adjacent subtitles, but the `Options.anki_local_fuzzy_window` safely buffers logic already.
