# Proposal: Fix 5 Failing Tests

**ZID**: 20260510125327
**Date**: 2026-05-10
**Status**: Proposed

## Summary

Fix 5 failing acceptance tests related to Natural Progression, Drum Window indexing, Jerk-Back, and OSD rendering. The failures are caused by recent changes to the immersion engine logic, particularly around `get_center_index` and `get_effective_boundaries` functions.

## Failing Tests

1. **test_20260501005019_natural_progression** - Expected transition to sub 2 at 2.05s, got 1
2. **test_20260506223500_natural_progression_skip** - Expected Natural Progression to advance to index 2 at 2.05s, got 1
3. **test_dw_mouse_selection_engine_double_click** - assert 1 == 2 (dw_cursor['word'] should be -1 but got 1)
4. **test_has_phrase_phrase_first_order** - drum OSD returned empty render after seek
5. **test_phrase_jerkback_advances_active_idx_in_overlap** - Expected Jerk-Back to advance to sub 2 at 2.05s; got 1

## Root Cause Analysis

### Natural Progression Failures (Tests 1, 2, 5)

The Natural Progression logic in `get_center_index` is missing critical checks that were added in commits:
- `c55eb69a` (20260509191227) - Added expiry check using padded end time
- `d4b7631b` (20260509194018) - Fixed expiry to use padded end in both PHRASE and MOVIE modes, added guard for Overlap Priority

The current code (lines 710-720 in `lls_core.lua`):
```lua
if active_idx and active_idx ~= -1 and active_idx + 1 <= #subs and subs[active_idx + 1] then
    local next_idx = active_idx + 1
    local s_next, e_next = get_effective_boundaries(subs[next_idx], next_idx)
    if s_next and e_next and time_pos >= s_next - Options.nav_tolerance and time_pos <= e_next then
        return next_idx  -- Missing expiry check!
    end
end
```

Should be:
```lua
if active_idx and active_idx ~= -1 and active_idx + 1 <= #subs and subs[active_idx + 1] then
    local next_idx = active_idx + 1
    local s_next, e_next = get_effective_boundaries(subs, subs[next_idx], next_idx)
    if s_next and e_next and time_pos >= s_next - Options.nav_tolerance and time_pos <= e_next then
        local _, e_current = get_effective_boundaries(subs, subs[active_idx], active_idx)
        -- Natural Progression: transition only after the current sub's padded window expires.
        if time_pos >= e_current - Options.nav_tolerance then
            return next_idx
        end
    end
end
```

Additionally, the Overlap Priority logic (lines 743-749) is missing the guard:
```lua
if best < #subs then
    local next_sub = subs[best + 1]
    local s_next, _ = get_effective_boundaries(next_sub, best + 1)
    if time_pos >= s_next - Options.nav_tolerance then
        return best + 1
    end
end
```

Should be:
```lua
if best < #subs and time_pos > subs[best].end_time then
    local next_sub = subs[best + 1]
    local s_next, _ = get_effective_boundaries(subs, next_sub, best + 1)
    if time_pos >= s_next - Options.nav_tolerance then
        return best + 1
    end
end
```

### Function Signature Mismatch

The `get_effective_boundaries` function was changed in commits to take `subs` as a parameter:
- `c55eb69a` (20260509191227) - Changed signature from `get_effective_boundaries(sub, idx)` to `get_effective_boundaries(subs, sub, idx)`

Current code (line 667):
```lua
local function get_effective_boundaries(sub, idx)
    if not sub then return nil, nil end
    local subs = Tracks.pri.subs
    ...
```

Should be:
```lua
local function get_effective_boundaries(subs, sub, idx)
    if not sub then return nil, nil end
    ...
```

This change is necessary for secondary track support.

### Double-Click Test Failure (Test 3)

The test expects `dw_cursor['word']` to be -1 after double-clicking line 2, but it's getting 1. This suggests the cursor is not being properly cleared after the double-click seek operation.

### OSD Rendering Test Failure (Test 4)

The test expects non-empty drum OSD render after seek, but gets empty. This may be related to:
1. Tooltip pre-loading logic added in commit `1368f1af` (20260509170743)
2. Secondary subtitle visibility changes in commit `99dfa71c` (20260509180338)

## Proposed Fixes

### Fix 1: Update `get_effective_boundaries` signature

Change the function signature to accept `subs` parameter for secondary track support.

### Fix 2: Restore Natural Progression expiry check

Add the missing expiry check that ensures we only transition to the next sub after the current sub's padded window expires.

### Fix 3: Add Overlap Priority guard

Add the guard that only applies Overlap Priority when `time_pos > subs[best].end_time`.

### Fix 4: Fix double-click cursor clearing

Investigate and fix why `dw_cursor['word']` is not being set to -1 after double-click.

### Fix 5: Fix OSD rendering after seek

Investigate and fix why drum OSD returns empty render after seek.

## Implementation Plan

1. Update `get_effective_boundaries` function signature
2. Update all calls to `get_effective_boundaries` to pass `subs` parameter
3. Add Natural Progression expiry check
4. Add Overlap Priority guard
5. Fix double-click cursor clearing
6. Fix OSD rendering after seek
7. Run tests to verify all fixes

## Testing

Run the full test suite to ensure:
- All 5 failing tests now pass
- No regressions in other tests
- Natural Progression works correctly with both 200ms and 1000ms padding values
