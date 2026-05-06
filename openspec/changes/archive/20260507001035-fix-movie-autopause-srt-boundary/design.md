# Design: MOVIE Mode Autopause SRT Boundary Compliance Fix

**Change ID:** 20260507001035-fix-movie-autopause-srt-boundary  
**Version:** 1.0  
**Date:** 2026-05-07

---

## 1. Technical Overview

This design specifies the implementation strategy for enforcing SRT boundary compliance in MOVIE mode autopause operations. The fix addresses a guard condition deficiency in the boundary calculation subsystem that permits pause activation prior to the current subtitle's SRT-defined terminus.

---

## 2. Architecture Context

### 2.1 Relevant System Components

The autopause system operates through a coordinated pipeline of three primary components:

```
┌─────────────────────────────────────────────────┐
│  mpv Event Loop (OnTick Callback)              │
├─────────────────────────────────────────────────┤
│                                                │
│  ┌────────────────────────────────────────┐    │
│  │ tick_autopause(time_pos)               │    │
│  │ • Reads current playback position      │    │
│  │ • Resolves active subtitle index       │    │
│  │ • Calculates pause distance            │    │
│  │ • Triggers pause if threshold met      │    │
│  └────────────────────────────────────────┘    │
│           ↓                                     │
│  ┌────────────────────────────────────────┐    │
│  │ get_effective_boundaries(sub, idx)     │    │
│  │ • Retrieves SRT raw boundaries         │    │
│  │ • Applies audio padding buffers        │    │
│  │ • [MOVIE MODE] Calculates handover     │    │
│  │ • [GUARDS] Enforces invariants         │    │
│  │ • Returns (start, stop) tuple          │    │
│  └────────────────────────────────────────┘    │
│           ↓                                     │
│  ┌────────────────────────────────────────┐    │
│  │ get_center_index(subs, time_pos)       │    │
│  │ • Maintains Sticky Focus Sentinel      │    │
│  │ • Determines active subtitle index     │    │
│  └────────────────────────────────────────┘    │
│                                                │
└─────────────────────────────────────────────────┘
```

### 2.2 Current Guard Condition Analysis

**File Location:** `scripts/lls_core.lua`, lines 669–675

**Current Implementation:**
```lua
if FSM.IMMERSION_MODE == "MOVIE" and idx and subs and idx < #subs then
    stop = subs[idx + 1].start_time - pad_start
    -- Guard against stop being before start (extreme overlaps)
    if stop < start then stop = sub.end_time end
end
```

**Guard Characteristics:**
- **Predicate:** `stop < start` (stop boundary precedes start boundary)
- **Trigger Frequency:** Extremely rare (only extreme full overlaps)
- **Enforcement:** Fallback to raw SRT `end_time` (no padding)

**Problem:** The guard addresses a pathological case but ignores the common case where the MOVIE mode boundary calculation produces `stop < sub.end_time` due to short inter-subtitle gaps.

---

## 3. Proposed Boundary Enforcement Model

### 3.1 Modified Guard Condition

**Target Change:** Replace the guard condition at line 674

**Old Guard:**
```lua
if stop < start then stop = sub.end_time end
```

**New Guard:**
```lua
if stop < sub.end_time then stop = sub.end_time end
```

### 3.2 Logical Justification

The new guard enforces a fundamental invariant of the autopause system:

> **Invariant:** The effective pause boundary shall not precede the subtitle's SRT-defined end time.

This invariant is justified by the following reasoning:

1. **Specification Requirement:** Subtitles must be played to their SRT-defined boundaries
2. **MOVIE Mode Intent:** Seamless handover should optimize transitions, not truncate content
3. **Causality Preservation:** Users should hear all content defined by subtitle timing
4. **Padding Role:** `audio_padding` is supplementary (extends beyond SRT), not restrictive (before SRT)

### 3.3 Behavior Under Different Gap Conditions

**Case 1: Large Inter-Subtitle Gap (gap ≥ 0.35 seconds)**

Example:
- Subtitle N: `end_time = 10.000s`, Subtitle N+1: `start_time = 10.500s`
- Calculated: `stop = 10.5 - 0.2 = 10.3s`
- Check: `10.3 < 10.0`? No → No clamping
- **Result:** Seamless handover operates normally; pause at ~10.3s

**Case 2: Small Inter-Subtitle Gap (0 < gap < 0.35 seconds)**

Example:
- Subtitle N: `end_time = 10.000s`, Subtitle N+1: `start_time = 10.100s`
- Calculated: `stop = 10.1 - 0.2 = 9.9s`
- Check: `9.9 < 10.0`? Yes → Clamp to `10.0s`
- **Result:** Pause at ~10.0s (respects SRT boundary)

**Case 3: Extreme Overlap (Subtitle N+1 starts before Subtitle N ends)**

Example:
- Subtitle N: `end_time = 10.000s`, Subtitle N+1: `start_time = 9.800s`
- Calculated: `stop = 9.8 - 0.2 = 9.6s`
- Check: `9.6 < 10.0`? Yes → Clamp to `10.0s`
- **Result:** Conservative behavior; pause at N's end

---

## 4. Implementation Procedure

### 4.1 Modification Steps

1. **Locate Target:** File `scripts/lls_core.lua`, line 674
2. **Identify Context:** Locate the `get_effective_boundaries()` function and the MOVIE mode guard
3. **Execute Change:** Replace guard condition text exactly as specified
4. **Preserve Context:** Maintain all surrounding code, comments, and formatting

### 4.2 Code Modification Specification

**File:** `scripts/lls_core.lua`  
**Function:** `get_effective_boundaries(sub, idx)`  
**Line Range:** 673–675 (3-line guard block)

**Original Block:**
```lua
        -- Guard against stop being before start (extreme overlaps)
        if stop < start then stop = sub.end_time end
```

**Modified Block:**
```lua
        -- Guard: never pause before SRT end_time (short gaps shrink the handover boundary)
        if stop < sub.end_time then stop = sub.end_time end
```

**Change Details:**
- Line 673: Comment updated to reflect new guard semantics
- Line 674: Predicate changed from `stop < start` to `stop < sub.end_time`
- Net lines changed: 2 lines modified, 0 lines added/removed

### 4.3 Validation Checkpoints

After modification, verify:

1. **Syntax Integrity:** Lua parser accepts file without errors
2. **Contextual Alignment:** Function signature and parameter usage unchanged
3. **Comment Consistency:** Guard comment accurately reflects new behavior
4. **Whitespace Preservation:** Indentation and formatting consistent with surrounding code

---

## 5. Testing Strategy

### 5.1 Manual Test Cases

#### Test Case 1: Small Gap Boundary Compliance
**Precondition:**
- Load subtitle file with consecutive subtitles separated by 100ms gap
- Enable MOVIE mode autopause

**Procedure:**
- Play subtitle N
- Observe autopause firing behavior near N's end

**Expected Result:**
- Autopause fires at or near subtitle N's SRT `end_time`
- No audio truncation at subtitle N terminus
- Subtitle N audio is fully heard before pause

**Pass Criteria:** Pause occurs within 0.15 seconds after SRT `end_time` (pause_padding tolerance)

#### Test Case 2: Large Gap Seamless Transition
**Precondition:**
- Load subtitle file with subtitles separated by 0.5 second gaps
- Enable MOVIE mode autopause

**Procedure:**
- Play subtitle N
- Observe pause point relative to next subtitle's start

**Expected Result:**
- Seamless handover mechanism functions normally
- Pause occurs in gap region between subtitles N and N+1
- No regression in cinematic flow

**Pass Criteria:** Pause occurs at approximately `N+1.start_time - audio_padding_start`

#### Test Case 3: Extreme Overlap Robustness
**Precondition:**
- Load subtitle file with pathological timing (N+1 starts before N ends)
- Enable MOVIE mode autopause

**Procedure:**
- Play subtitle N and observe behavior
- Verify no undefined behavior or crash

**Expected Result:**
- System handles overlap gracefully
- Pause fires at subtitle N's end
- No stuttering or jitter

**Pass Criteria:** Clean pause execution without error

### 5.2 Regression Testing

Verify no degradation in:
- PHRASE mode autopause (unaffected by change; uses original `sub.end_time + pad_end`)
- Large-gap transitions (seamless handover should remain unchanged)
- Karaoke mode interaction (phrase-level pause prevention unaffected)
- Loop and scheduled replay modes (use independent pause logic)

---

## 6. Configuration & Parameters

### 6.1 Relevant Configuration Values

| Parameter | Value | Location | Role |
|-----------|-------|----------|------|
| `pause_padding` | 0.15s | lls_core.lua:199 | Lookahead before effective boundary |
| `audio_padding_start` | 200ms | lls_core.lua:470 | Pre-roll buffer (padding before SRT start) |
| `audio_padding_end` | 200ms | lls_core.lua:471 | Post-roll buffer (padding after SRT end) |
| `immersion_mode_default` | "PHRASE" | lls_core.lua:477 | Default mode at startup |

### 6.2 No Configuration Changes Required

The fix requires no modifications to:
- User-facing configuration values
- Default padding buffers
- Pause timing parameters
- Mode selection defaults

---

## 7. Impact Assessment

### 7.1 Direct Impact

| Component | Impact | Risk |
|-----------|--------|------|
| `get_effective_boundaries()` | Guard condition modified | Very Low |
| `tick_autopause()` | No changes; uses modified boundaries | Very Low |
| `get_center_index()` | No changes; uses modified boundaries | Very Low |
| MOVIE mode immersion | Corrected behavior | Very Low |
| PHRASE mode behavior | No changes | None |

### 7.2 Performance Impact

- **Computational:** Negligible (single conditional comparison)
- **Memory:** No change
- **Latency:** No measurable impact

### 7.3 User-Facing Impact

- **Positive:** Subtitles with short gaps now play to completion without truncation
- **Negative:** None identified
- **Neutral:** Large-gap seamless transitions unchanged

---

## 8. Rollback Procedure

If unexpected behavior occurs post-deployment:

1. **Restore Original Guard:** Revert line 674 to `if stop < start then stop = sub.end_time end`
2. **Reload Scripts:** Reload mpv configuration or restart player
3. **Verification:** Confirm pre-fix behavior restored

Estimated rollback time: < 2 minutes

---

## 9. Future Considerations

### 9.1 Potential Enhancements

1. **Configurable Gap Threshold:** Allow users to define minimum gap size for seamless handover
2. **Gap-Aware Padding:** Dynamically adjust `audio_padding_start` based on inter-subtitle gap size
3. **MOVIE Mode Variants:** Separate "true seamless" (hand handover at gap midpoint) from "boundary-preserving" modes

### 9.2 Deferred Out of Scope

These considerations are explicitly deferred to future iterations and are not addressed by this proposal.

---

## 10. Sign-Off & Approvals

| Role | Name | Date | Status |
|------|------|------|--------|
| Design Lead | (TBD) | — | Pending |
| Architecture | (TBD) | — | Pending |
| QA Lead | (TBD) | — | Pending |

