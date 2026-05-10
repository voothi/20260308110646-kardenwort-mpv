# Design: Fix 5 Failing Tests

**ZID**: 20260510125327
**Date**: 2026-05-10

## Architecture Overview

The fixes focus on the immersion engine's subtitle navigation logic, specifically the `get_center_index` function which determines which subtitle should be active at a given time position.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Immersion Engine                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              get_center_index(subs, time_pos)            │  │
│  │                                                          │  │
│  │  1. Sticky Focus Sentinel (lines 690-708)               │  │
│  │     - Prioritize active index if in padded window       │  │
│  │                                                          │  │
│  │  2. Natural Progression (lines 710-720) [FIX NEEDED]    │  │
│  │     - Transition to next sub when current expires       │  │
│  │     - Missing: expiry check using padded end time       │  │
│  │                                                          │  │
│  │  3. Binary Search (lines 722-732)                      │  │
│  │     - Find best matching subtitle by start_time         │  │
│  │                                                          │  │
│  │  4. Overlap Priority (lines 739-749) [FIX NEEDED]       │  │
│  │     - Next sub wins if its padded start has begun       │  │
│  │     - Missing: guard to only apply past end_time        │  │
│  │                                                          │  │
│  │  5. Gap Handling (lines 751-769)                       │  │
│  │     - Proximity fallback for gaps between subs          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │      get_effective_boundaries(subs, sub, idx) [FIX]     │  │
│  │                                                          │  │
│  │  - Calculate padded start: sub.start_time - pad_start   │  │
│  │  - Calculate padded end: sub.end_time + pad_end         │  │
│  │  - MOVIE mode: seamless handover at next padded start   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Detailed Design

### Fix 1: Update `get_effective_boundaries` signature

**Current:**
```lua
local function get_effective_boundaries(sub, idx)
    if not sub then return nil, nil end
    local subs = Tracks.pri.subs  -- Hardcoded to primary track
    ...
```

**Fixed:**
```lua
local function get_effective_boundaries(subs, sub, idx)
    if not sub then return nil, nil end
    -- Use passed subs parameter (supports both primary and secondary)
    ...
```

**Rationale:** The function needs to work with both primary and secondary subtitle tracks. Hardcoding `Tracks.pri.subs` prevents secondary track support.

### Fix 2: Restore Natural Progression expiry check

**Current:**
```lua
if active_idx and active_idx ~= -1 and active_idx + 1 <= #subs and subs[active_idx + 1] then
    local next_idx = active_idx + 1
    local s_next, e_next = get_effective_boundaries(subs[next_idx], next_idx)
    if s_next and e_next and time_pos >= s_next - Options.nav_tolerance and time_pos <= e_next then
        return next_idx  -- Immediate transition - WRONG!
    end
end
```

**Fixed:**
```lua
if active_idx and active_idx ~= -1 and active_idx + 1 <= #subs and subs[active_idx + 1] then
    local next_idx = active_idx + 1
    local s_next, e_next = get_effective_boundaries(subs, subs[next_idx], next_idx)
    if s_next and e_next and time_pos >= s_next - Options.nav_tolerance and time_pos <= e_next then
        local _, e_current = get_effective_boundaries(subs, subs[active_idx], active_idx)
        -- Natural Progression: transition only after current sub's padded window expires
        if time_pos >= e_current - Options.nav_tolerance then
            return next_idx
        end
    end
end
```

**Rationale:** Without the expiry check, we transition to the next sub as soon as we enter its padded zone, even if the current sub's padded window hasn't expired. This causes the test failures at 2.05s when:
- Sub 1 ends at 2.0s, padded end at 2.2s (with 200ms padding)
- Sub 2 starts at 2.2s, padded start at 2.0s
- At 2.05s, we're in the overlap zone, but sub 1's padded window hasn't expired yet

### Fix 3: Add Overlap Priority guard

**Current:**
```lua
if best < #subs then
    local next_sub = subs[best + 1]
    local s_next, _ = get_effective_boundaries(next_sub, best + 1)
    if time_pos >= s_next - Options.nav_tolerance then
        return best + 1  -- Can override active sub inside its SRT window - WRONG!
    end
end
```

**Fixed:**
```lua
if best < #subs and time_pos > subs[best].end_time then
    local next_sub = subs[best + 1]
    local s_next, _ = get_effective_boundaries(subs, next_sub, best + 1)
    if time_pos >= s_next - Options.nav_tolerance then
        return best + 1
    end
end
```

**Rationale:** The guard `time_pos > subs[best].end_time` ensures we only apply Overlap Priority when we're in a true gap (past the actual SRT end time). Without this guard, the next sub's padded start could override the current sub even when we're inside the current sub's raw SRT window.

### Fix 4: Fix double-click cursor clearing

**Investigation needed:** The test expects `dw_cursor['word']` to be -1 after double-clicking line 2. Need to check the `cmd_dw_double_click` function to ensure it properly clears the cursor word index.

**Likely location:** `cmd_dw_double_click` function around line 5085 in `lls_core.lua`.

### Fix 5: Fix OSD rendering after seek

**Investigation needed:** The test expects non-empty drum OSD render after seek. Need to check:
1. Tooltip pre-loading logic (commit `1368f1af`)
2. Secondary subtitle visibility changes (commit `99dfa71c`)
3. Drum window rendering logic

**Likely locations:**
- `update_media_state` function (tooltip pre-loading)
- `cmd_cycle_sec_sid` function (secondary visibility)
- Drum window rendering functions

## Data Flow

### Natural Progression Flow

```
time_pos = 2.05s
    │
    ▼
get_center_index(subs, 2.05)
    │
    ├─► Sticky Focus: active_idx = 1, check if in padded window
    │   - s = 2.0 - 0.2 = 1.8s
    │   - e = 2.0 + 0.2 = 2.2s
    │   - 1.8 <= 2.05 <= 2.2 → YES, return 1 (STOPS HERE - WRONG!)
    │
    └─► Natural Progression (should be checked first):
        - Check if next sub's padded zone is active
        - s_next = 2.2 - 0.2 = 2.0s
        - e_next = 4.0 + 0.2 = 4.2s
        - 2.0 <= 2.05 <= 4.2 → YES
        - Check if current sub's padded window has expired
        - e_current = 2.0 + 0.2 = 2.2s
        - 2.05 >= 2.2 - 0.05 → NO, don't transition yet
        - Return 1 (CORRECT!)
```

**Issue:** The Sticky Focus check happens BEFORE Natural Progression, so we never reach the expiry check. The order needs to be:
1. Natural Progression (check if we should transition)
2. Sticky Focus (if no transition, check if we're still in current sub's padded window)

## Edge Cases

### Large Padding Values (1000ms)

With `audio_padding_start = audio_padding_end = 1000ms`:
- Sub 1: 1.0-2.0s → padded: 0.0-3.0s
- Sub 2: 2.2-4.0s → padded: 1.2-5.0s
- Overlap zone: 1.2-3.0s

At 2.05s:
- Sticky Focus: 0.0 <= 2.05 <= 3.0 → YES, return 1
- Natural Progression:
  - Next sub's padded zone: 1.2 <= 2.05 <= 5.0 → YES
  - Current sub's padded expiry: 2.05 >= 3.0 - 0.05 → NO
  - Don't transition, return 1

This is CORRECT behavior - we should stay on sub 1 until its padded window expires at 3.0s.

### Small Gaps Between Subtitles

When gap < 2 * padding:
- Overlap Priority guard prevents premature switching
- Natural Progression expiry check ensures smooth transition

### Rewind Transit

The `TIMESEEK_INHIBIT_UNTIL` mechanism (commit `438fa31e`) was added to handle rewind transit, but was later modified (commit `d28ee994`) to clear it in specific places instead of inhibiting Natural Progression.

## Testing Strategy

### Unit Tests
- Test `get_effective_boundaries` with both primary and secondary subs
- Test `get_center_index` with various time positions and padding values

### Integration Tests
- Test Natural Progression with 200ms padding
- Test Natural Progression with 1000ms padding
- Test double-click cursor clearing
- Test OSD rendering after seek

### Regression Tests
- Ensure all existing tests still pass
- Test edge cases (large gaps, small gaps, rewind transit)
