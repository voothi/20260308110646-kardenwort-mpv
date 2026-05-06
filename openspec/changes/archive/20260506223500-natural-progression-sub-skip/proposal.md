# Proposal: Natural Progression Sub-Skip Fix (v1.58.53)

## Problem

In PHRASE mode with AUTOPAUSE ON and large `audio_padding_start` values (e.g., 1000ms), intermediate subtitles are **visually skipped** in the Drum Window. The subtitle plays audibly but never receives the white DW focus — the next subtitle immediately takes over.

**Reported**: Conversation anchors 20260506203418, 20260506214011, 20260506220111.

**Example**: With subs 102, 103, 104 where padding creates overlapping zones:
- Sub 102 padded end: ~54.472s
- Sub 103 padded start: 52.519s, padded end: 56.066s
- Sub 104 padded start: 54.106s

When sub 102's sticky sentinel expires at ~54.472s, `get_center_index` performs a binary search finding `best=103`, then promotes to `best+1=104` because sub 104's padded start (54.106s) satisfies the Overlap Priority check. Sub 103 is never set as `ACTIVE_IDX`.

## Root Cause

The "Overlap Priority" heuristic in `get_center_index` was designed for the default 200ms padding case where at most one transition overlap exists. With 1000ms padding, **multiple subtitles' padded zones overlap simultaneously**. The binary search `best` already points to the correct next sub, but `best+1` promotion jumps one further, skipping the intermediate subtitle.

The immersion_engine spec requires: *"The engine MUST immediately transition to `i+1`"* — meaning the **next consecutive sub**, not `best+1` from binary search. The existing Overlap Priority implementation violated this for large padding values.

## Objective

Implement a **One-step Natural Progression** check that strictly enforces the spec's `i → i+1` transition rule regardless of how large the padding values are. Sub-skipping must be impossible in PHRASE mode.

## Non-Goals

- Changing MOVIE mode behavior (gapless handover is unaffected).
- Modifying jerk-back timing or overshoot.
- Changing padding defaults.
