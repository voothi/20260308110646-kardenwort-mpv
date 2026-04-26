## Context

The `lls_core.lua` script handles subtitle loading and clipboard management. Recent updates introduced a fallback to internal tracks in `cmd_copy_sub` but placed it after native property checks. Additionally, the ASS loader was filtering Cyrillic characters, which prevented translation tracks (usually Russian) from being indexed.

## Goals / Non-Goals

**Goals:**
- Ensure `cmd_copy_sub` behaves identically regardless of OSD state by prioritizing internal memory-resident data.
- Standardize the merging logic across both SRT and ASS loaders.
- Restore the ability to copy Russian translations from ASS files.

**Non-Goals:**
- Modifying the Drum Window rendering logic.
- Changing the Anki export logic.

## Decisions

- **Decision: Prioritize Internal Index in `cmd_copy_sub`**: Move the logic that extracts from `Tracks.pri.subs` and `Tracks.sec.subs` to the top of the fallback chain (after context check). Rationale: Internal data is more reliable for language-aware filtering (Mode A/B) than native properties.
- **Decision: Unify Merging Window**: Implement a 10-entry lookback loop for SRT merging, matching the ASS implementation. Rationale: Interleaved tracks (karaoke + translation) require more than 1-entry lookback to merge correctly.
- **Decision: Remove Character-Set Load Filtering**: Remove `not has_cyrillic` from the ASS loader. Rationale: The system should index all tracks; filtering should happen at display/copy time using `is_target` or `has_cyrillic` checks, not during ingestion.

## Risks / Trade-offs

- [Risk] Memory usage increase for large ASS files with many translation tracks. → [Mitigation] mpv memory limit is high for scripts; current sub tables are relatively small.
- [Risk] Duplicate lines appearing if merging logic is flawed. → [Mitigation] 10-entry lookback window is proven stable in the existing ASS implementation.
