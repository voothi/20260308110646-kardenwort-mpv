## Context

The current highlighting logic in `scripts/lls_core.lua` (specifically `calculate_highlight_stack`) uses a fixed 10-second fuzzy window (`anki_local_fuzzy_window`) and a 15-subtitle scan range for multi-word terms. This high-recall approach works well in Global Mode but causes excessive "bleed" in Local Mode, where highlights from future or past scenes appear in the current subtitle view.

## Goals / Non-Goals

**Goals:**
- Increase highlight precision in "Local Mode" (Global Highlight OFF).
- Prevent common words (e.g., "die") from appearing as highlights when they belong to notes exported from different time ranges.
- Reduce the computational overhead of scanning 30 subtitles (±15) for every word in every visible line when in local mode.

**Non-Goals:**
- Changing the behavior of "Global Highlight" mode.
- Implementing a completely new highlight engine.

## Decisions

### 1. Tighten the Local Fuzzy Window
We will reduce the default value of `anki_local_fuzzy_window` from `10.0` to `2.0`. 
- **Rationale**: 2 seconds is generally sufficient to account for minor alignment drift between subtitles and audio timestamps, while preventing "bleed" from adjacent or nearby sentences.
- **Alternatives**: Keeping the 10s window (rejected: causes current issue). Reducing to 0s (rejected: too brittle for varying subtitle durations).

### 2. Restrict Local Subtitle Scan Range
For multi-word terms (where `#term_words > 1`), we will reduce the scan range from ±15 subtitles to ±3 subtitles when `anki_global_highlight` is `false`.
- **Rationale**: Phrases split across segments rarely span more than 2-3 subtitle blocks. A 15-block scan (potentially 30-60 seconds of dialogue) is logically "global" rather than "local."
- **Alternatives**: Disabling the scan entirely (rejected: would break highlights for phrases split exactly at segment boundaries).

### 3. Configurable Strictness
The `anki_local_fuzzy_window` and the scan range will remain tied to the `Options` table to allow users to restore the old behavior if desired.

## Risks / Trade-offs

- **[Risk] High-speed dialogue clipping** → If a speaker is extremely fast and subtitles are fragmented, a 2s window might miss a note saved at the very start of a long sentence.
- **Mitigation**: Users can increase `anki_local_fuzzy_window` in their `mpv.conf` if they experience missing highlights.
