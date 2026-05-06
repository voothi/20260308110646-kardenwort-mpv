# Proposal: MOVIE Mode Autopause SRT Boundary Compliance

**Change ID:** 20260507001035-fix-movie-autopause-srt-boundary  
**Status:** Proposed  
**Priority:** High  
**Date:** 2026-05-07

---

## 1. Executive Summary

This proposal addresses a critical defect in the MOVIE mode autopause implementation whereby the effective pause boundary calculation violates the specified requirement that subtitles must be played to their exact boundaries as defined in the SRT (SubRip) file. The defect manifests as premature pause activation when consecutive subtitles are separated by small inter-subtitle gaps (< 0.35 seconds), resulting in audio truncation at the conclusion of the subtitle segment.

**Impact Severity:** Medium-High  
**Affected Component:** `lls_core.lua` — `get_effective_boundaries()` function (line 674)  
**Scope of Fix:** Single-line guard condition modification

---

## 2. Problem Statement

### 2.1 Current Behavior

In MOVIE mode immersion, the autopause system implements a "seamless handover" mechanism wherein the effective end boundary of subtitle `N` is redefined from its SRT-defined `end_time` to the SRT-defined start time of subtitle `N+1`, minus the `audio_padding_start` buffer. This design intent is to facilitate gapless cinematic transitions without overlapping audio loops.

However, the existing guard condition (line 674):
```lua
if stop < start then stop = sub.end_time end
```

only protects against extreme full overlaps (where the calculated `stop` precedes the calculated `start`). This narrow protection fails to account for the common scenario wherein the next subtitle's padded start point falls **before** the current subtitle's SRT-defined `end_time`, due to small inter-subtitle gaps.

### 2.2 Manifestation Example

**Concrete Example Scenario:**
- Subtitle N: `end_time = 10.000 seconds`
- Subtitle N+1: `start_time = 10.100 seconds` (100ms inter-subtitle gap)
- `audio_padding_start = 200 milliseconds` (0.2 seconds)

**Calculation Under Current Logic:**
1. MOVIE mode effective boundary: `stop = 10.1 - 0.2 = 9.9 seconds`
2. Autopause fires when: `sub_end - time_pos ≤ pause_padding (0.15s)`
3. Pause activation: `9.9 - 0.15 = 9.75 seconds`
4. **Result:** 0.25 seconds of subtitle N audio is never heard

### 2.3 Specification Violation

The current behavior violates the documented requirement in the Immersion Engine specification:

> "Subtitles shall be played to their exact boundaries as defined in the SRT source file, ensuring no audio truncation at subtitle terminus."

This defect compromises the educational efficacy of the system, particularly in language acquisition contexts where every syllable or audio fragment carries semantic or phonetic significance.

---

## 3. Root Cause Analysis

The root cause is a insufficient guard condition that assumes only extreme pathological overlaps require clamping. The guard does not account for:

1. **Short Inter-Subtitle Gaps:** When consecutive subtitles are separated by intervals smaller than `audio_padding_start`, the MOVIE mode boundary calculation naturally produces a `stop` value that precedes the current subtitle's `end_time`.

2. **Cumulative Padding Effects:** The combination of `audio_padding_start` (200ms) and `pause_padding` (150ms) totals 350ms of "early" pause activation, which easily exceeds short subtitle gaps common in contemporary film and educational media.

3. **Design Intent Misalignment:** The seamless handover feature was intended for subtitle transitions with natural gaps, not for enforcement against subtitle-end truncation.

---

## 4. Proposed Solution

Modify the guard condition to enforce the invariant: **the effective boundary shall never precede the subtitle's SRT-defined `end_time`.**

**Modified Guard Condition:**
```lua
if stop < sub.end_time then stop = sub.end_time end
```

### 4.1 Solution Characteristics

- **Minimalist:** Single-line modification; no algorithmic restructuring required
- **Non-Breaking:** Preserves MOVIE mode seamless handover for subtitles with sufficient gaps
- **Specification-Compliant:** Enforces exact SRT boundary playback as documented
- **Deterministic:** Removes pathological behavior without introducing heuristic ambiguity

### 4.2 Behavioral Impact

| Scenario | Before | After | Impact |
|----------|--------|-------|--------|
| Large gap (gap > 0.35s) | Handover at `next_sub.start - pad_start` | Handover at `next_sub.start - pad_start` | No change ✓ |
| Small gap (gap < 0.35s) | Pause before `current_sub.end_time` | Pause at ~`current_sub.end_time` | Fixes truncation ✓ |
| Extreme overlap | Clamped to `current_sub.end_time` | Clamped to `current_sub.end_time` | No change ✓ |

---

## 5. Non-Goals

The following are explicitly out of scope:

- Refactoring of the autopause architecture or FSM state management
- Modification of padding configuration defaults
- Changes to PHRASE mode behavior or boundaries
- Alteration of focus sentinel (sticky focus) logic

---

## 6. Acceptance Criteria

1. **Functional:** Subtitles with gaps ≤ 0.3 seconds play to their SRT `end_time` without truncation
2. **Regression:** MOVIE mode seamless handover functions normally for subtitles with gaps > 0.35 seconds
3. **Code Quality:** No additional complexity or computational overhead introduced
4. **Testing:** Manual verification with test cases covering small-gap and large-gap scenarios

---

## 7. Implementation Complexity

**Effort Estimate:** < 1 hour (including testing and documentation)  
**Risk Level:** Very Low (isolated, single-line change with clear invariant)  
**Deployment Risk:** Negligible (purely behavioral correction, no API or configuration changes)

---

## 8. References

- **Specification:** Immersion Engine Specification (`openspec/specs/immersion-engine/spec.md`)
- **Component:** lls_core.lua, lines 660–678 (`get_effective_boundaries` function)
- **Related Functions:** 
  - `tick_autopause()` (line 5179)
  - `get_center_index()` (line 680)

---

## 9. Approval & Sign-Off

| Role | Status | Date |
|------|--------|------|
| Architecture Review | Pending | — |
| Implementation Lead | Pending | — |
| QA Sign-Off | Pending | — |

