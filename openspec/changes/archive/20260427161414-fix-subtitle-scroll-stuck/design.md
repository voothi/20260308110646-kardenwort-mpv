## Context

The `load_sub` function in `lls_core.lua` is responsible for parsing external subtitle files (SRT/ASS) into an internal table for navigation and display. Currently, it employs an aggressive merging logic that searches back 10 entries to find subtitles with identical raw text. When found, it extends the `end_time` of the older entry and discards the new one. This causes intermediate unique subtitles to be logically "swallowed" when repetitive tags like `[Music]` appear non-consecutively, breaking the index-based seeking logic in `cmd_dw_seek_delta`.

## Goals / Non-Goals

**Goals:**
- Fix the forward-scrolling deadlock by ensuring every distinct subtitle event has a unique index.
- Restrict subtitle merging to strictly consecutive and temporally adjacent segments.
- Ensure internal subtitle tracks are sorted by start time for reliable binary search.

**Non-Goals:**
- Implementing advanced fuzzy matching for subtitle merging.
- Changing the ASS rendering engine behavior.

## Decisions

- **Single-Link Lookback**: Modify the merging logic to only compare the current subtitle with the immediately preceding one (`subs[#subs]`). This ensures that if another subtitle (like "and fifteen") intervened, the next occurrence of a generic tag won't trigger a merge with the distant past.
- **Temporal Proximity Guard**: Introduce a 200ms gap limit for merging. Subtitles with identical text will only merge if the new segment starts within 0.2s of the previous segment's end time, or if they overlap.
- **Explicit SRT Sorting**: Invoke `table.sort` on the `subs` table after SRT parsing is complete, matching the behavior already present in the ASS branch.

## Risks / Trade-offs

- **Minimal Redundancy**: In cases where subtitle files are severely malformed (e.g., identical segments scattered out of order), this change may result in multiple entries for the same text. However, this is preferable to losing intermediate data and breaking navigation.
- **200ms Threshold**: While most consecutive same-text segments overlap or have 0ms gaps, some might have very small gaps. 200ms is a safe "human-imperceptible" window for merging technical splits.
