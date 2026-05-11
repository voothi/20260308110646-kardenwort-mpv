# Rewind/Autopause Logic Analysis

**ZID**: 20260510193230
**Date**: 2026-05-10
**Status**: Analysis Complete

## Problem Statement

The rewind logic (Shift+a/d) and repeat logic (s key) have several issues:

1. **Autopause suppression during rewind** doesn't work correctly in all cases
2. **PHRASE mode jerk-back** causes unwanted behavior during rewind transit
3. **Within-subtitle vs cross-subtitle rewind** distinction is missing
4. **Accumulator behavior** doesn't match user expectations
5. **Test failures** indicate regression in core logic

## Conversation Anchors

- 20260509130838: Initial problem report - rewinding causes repeat and stops recording
- 20260509132307: Need to switch to MOVIE mode during rewind
- 20260509132732: PHRASE mode feels overlay/jerking during rewind
- 20260509134754: Seems to work, create tests
- 20260509151742: Tests passing
- 20260509152735: Document changes
- 20260509153016: Apply changes
- 20260509153250: Why change test file?
- 20260509153344: Bring back test for 1000ms padding
- 20260509153630: Changed padding defaults to 1000ms
- 20260509153704: Are you sure about changing test?
- 20260509154626: Other model's changes are correct
- 20260509154002: Figure out test change
- 20260509154522: Can we fully test overlay cases?
- 20260509154924: Are PHRASE/MOVIE cases reliably covered?
- 20260509164040: 29/29 tests passing
- 20260509164131: Check on real fixtures
- 20260509164844: 37/37 tests passing
- 20260509165255: Update change artifacts
- 20260509165622: Archive change
- 20260509165936: New issue - tooltip doesn't work without secondary subs
- 20260509171121: Fix in place
- 20260509171136: Secondary sub toggle causes OSD twitch
- 20260509171814: Update state
- 20260509180017: Apply fix
- 20260509180927: Make tooltip work in srt mode
- 20260509182259: Create test
- 20260509183117: Check if test covers the issue
- 20260509183344: Error
- 20260509185322: Deal with test errors
- 20260509192319: Deal with tests
- 20260509194636: All tests passing - 666 passed
- 20260509200413: Check why regression occurred
- 20260509214653: GLM 5.1
- 20260509231404: Analysis - TIMESEEK_INHIBIT_UNTIL intact but state hygiene issue found
- 20260509233440: Problems with tests
- 20260510005940: 666 passed
- 20260510084327: Update archived change
- 20260510085426: Look at failing tests
- 20260510094211: OpenSpec: Add OpenCode
- 20260510124758: Look at tests and correct them
- 20260510150746: Simplify rewind logic - turn off autopause during rewind
- 20260510160820: Error
- 20260510162117: Within-subtitle rewind should maintain autopause
- 20260510170701: Clicks should accumulate
- 20260510171244: Timer passes before user resumes playback
- 20260510181657: 621 passed, 0 failed
- 20260510183143: Refine minimally invasive logic for rewinding
- 20260510191545: Doesn't work as it should

## Current Implementation Analysis

### cmd_seek_time (lines 6249-6313)

```lua
local function cmd_seek_time(dir)
    -- ... accumulator logic ...
    
    -- Time-based seek overrides repeat/loop state
    FSM.LOOP_MODE = "OFF"
    FSM.REPLAY_REMAINING = 0
    FSM.SCHEDULED_REPLAY_START = nil
    FSM.SCHEDULED_REPLAY_END = nil
    FSM.last_paused_sub_end = nil  -- Allow autopause to re-arm
    
    -- Suppress autopause during backward rewind transit
    local current_pos = mp.get_property_number("time-pos") or 0
    if delta < 0 then
        FSM.TIMESEEK_INHIBIT_UNTIL = math.max(FSM.TIMESEEK_INHIBIT_UNTIL or 0, current_pos)
    else
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
    end
    
    mp.commandv("seek", delta, "relative+exact")
    -- ... OSD logic ...
end
```

**Issues**:
1. `TIMESEEK_INHIBIT_UNTIL` is set to position **before** seek
2. Cleared when `time_pos > TIMESEEK_INHIBIT_UNTIL`
3. If user doesn't resume playback immediately, inhibit may never clear properly
4. No distinction between within-subtitle vs cross-subtitle rewind

### tick_autopause (lines 5238-5291)

```lua
local function tick_autopause(time_pos)
    if FSM.AUTOPAUSE ~= "ON" or FSM.SPACEBAR ~= "IDLE" then return end
    if FSM.SCHEDULED_REPLAY_START or FSM.LOOP_MODE == "ON" then return end
    if FSM.MEDIA_STATE == "NO_SUBS" then return end
    
    -- Skip autopause while transiting through rewind zone
    if FSM.TIMESEEK_INHIBIT_UNTIL and time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL then return end
    
    -- ... rest of autopause logic ...
end
```

**Issues**:
1. Uses `<=` so exact boundary tick is still suppressed
2. No consideration of whether we're still in the same subtitle
3. Doesn't handle the case where user rewinds within same subtitle

### master_tick (lines 5359-5557)

```lua
local function master_tick()
    -- ... universal jump detection ...
    
    -- Jerk-Back logic (PHRASE mode only)
    if FSM.IMMERSION_MODE == "PHRASE" and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN
       and not FSM.TIMESEEK_INHIBIT_UNTIL then
        if FSM.ACTIVE_IDX ~= -1 and active_idx > FSM.ACTIVE_IDX and active_idx <= FSM.ACTIVE_IDX + 5 then
            local s_next, _ = get_effective_boundaries(Tracks.pri.subs, Tracks.pri.subs[active_idx], active_idx)
            if s_next and (time_pos - s_next) > Options.nav_tolerance then
                mp.commandv("seek", s_next, "absolute+exact")
                FSM.IGNORE_NEXT_JUMP = true
                FSM.JUST_JERKED_TO = active_idx
            end
        end
    end
    
    -- Clear inhibit after jerk-back evaluated
    if FSM.TIMESEEK_INHIBIT_UNTIL and time_pos > FSM.TIMESEEK_INHIBIT_UNTIL then
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
    end
    
    -- ... rest of tick logic ...
end
```

**Issues**:
1. Jerk-back is suppressed during rewind (`not FSM.TIMESEEK_INHIBIT_UNTIL`)
2. But this doesn't address the overlay/jerking felt during rewind transit
3. The inhibit clearing happens after jerk-back evaluation, which is correct
4. No special handling for within-subtitle rewind

### get_center_index (lines 686-784)

```lua
function get_center_index(subs, time_pos)
    -- ... sticky sentinel logic ...
    
    -- One-step Natural Progression
    if active_idx and active_idx ~= -1 and active_idx + 1 <= #subs and subs[active_idx + 1] then
        local next_idx = active_idx + 1
        local s_next, e_next = get_effective_boundaries(subs, subs[next_idx], next_idx)
        if s_next and e_next and time_pos >= s_next - Options.nav_tolerance and time_pos <= e_next then
            local _, e_current = get_effective_boundaries(subs, subs[active_idx], active_idx)
            
            if time_pos >= e_current - Options.nav_tolerance then
                return next_idx
            end
        end
    end
    
    -- ... rest of logic ...
end
```

**Issues**:
1. Natural progression logic is correct
2. But during rewind, we might want to suppress this
3. The sticky sentinel logic might interfere with rewind behavior

### get_effective_boundaries (lines 667-684)

```lua
local function get_effective_boundaries(subs, sub, idx)
    local pad_start = (Options.audio_padding_start or 0) / 1000
    local pad_end = (Options.audio_padding_end or 0) / 1000
    
    local start = sub.start_time - pad_start
    local stop = sub.end_time + pad_end
    
    -- Movie Mode: Seamless handover at next subtitle's padded start
    if FSM.IMMERSION_MODE == "MOVIE" and idx and subs and idx < #subs then
        stop = subs[idx + 1].start_time - pad_start
        if stop < sub.end_time then stop = sub.end_time end
    end
    
    return start, stop
end
```

**Issues**:
1. MOVIE mode has seamless handover to prevent overlapping audio
2. PHRASE mode doesn't have this, which causes overlay during rewind
3. This is why user wants to switch to MOVIE-like behavior during rewind

## Test Failures

### test_20260501160807_dw_esc_staged_reset.py::TestImmersionRegressions::test_20260501005019_natural_progression

**Expected**: Transition to sub 2
**Got**: 1

This test checks natural progression in PHRASE mode. The failure suggests that the natural progression logic isn't working correctly.

### test_20260506223500_fixtures_load.py::test_20260506223500_natural_progression_skip

**Expected**: Advance to index 2 at 2.05s
**Got**: 1

Similar issue - natural progression not advancing.

### test_20260509080221_drum_window_indexing_simple.py::TestHistoricalRegressionsV2::test_dw_mouse_selection_engine_double_click

**Expected**: 1
**Got**: 2

This suggests an issue with double-click indexing.

### test_20260509085125_has_phrase_phrase_first.py::test_has_phrase_phrase_first_order

**Error**: drum OSD returned empty render after seek

This suggests an issue with OSD rendering after seek.

### test_20260509085150_cycle_never_lands_on.py::TestImmersionSuiteHardening::test_phrase_jerkback_advances_active_idx_in_overlap

**Expected**: Jerk-Back to advance to sub 2 at 2.05s
**Got**: 1

This test specifically checks jerk-back in PHRASE mode. The failure suggests that jerk-back isn't advancing the active index.

## Root Cause Analysis

### Primary Issue: TIMESEEK_INHIBIT_UNTIL Semantics

The current implementation has a fundamental semantic issue:

```
User at 10s, rewinds to 5s:
  TIMESEEK_INHIBIT_UNTIL = 10
  Autopause suppressed until time_pos > 10
  
Scenario 1: User resumes immediately
  Playback goes 5s -> 10s -> 11s
  At 10.001s, inhibit clears
  Autopause can fire at next subtitle boundary
  
Scenario 2: User waits 5 seconds before resuming
  Still at 5s, but inhibit = 10
  User resumes, playback goes 5s -> 10s -> 11s
  At 10.001s, inhibit clears
  Autopause can fire
  
Scenario 3: User rewinds further before resuming
  User at 5s, rewinds to 2s
  TIMESEEK_INHIBIT_UNTIL = max(10, 5) = 10
  Playback goes 2s -> 10s -> 11s
  At 10.001s, inhibit clears
  Autopause can fire
```

This seems correct in theory, but the issue is that:

1. **Within-subtitle rewind**: If I'm at 10.5s (in sub 3) and rewind to 10.2s (still in sub 3), should autopause still fire at the end of sub 3? Currently, `TIMESEEK_INHIBIT_UNTIL = 10.5`, so autopause is suppressed until 10.501s, which is past the end of sub 3.

2. **PHRASE mode overlay**: The user feels "jerk-back" and "overlay" during rewind transit. This is because PHRASE mode doesn't have the MOVIE-style seamless handover.

### Secondary Issue: Jerk-Back During Rewind

The jerk-back logic is designed to snap to subtitle boundaries in PHRASE mode. However, during rewind transit:

1. User rewinds from 10s to 5s
2. Playback resumes from 5s
3. As playback passes through subtitle boundaries, jerk-back might trigger
4. This causes unwanted seeking behavior

The current code suppresses jerk-back during rewind (`not FSM.TIMESEEK_INHIBIT_UNTIL`), but this doesn't prevent the overlay effect that the user feels.

### Tertiary Issue: Test Fixture Path

The test failure shows a path issue:
```
FileNotFoundError: [Errno 2] No such file or directory: 'U:\\voothi\\20260308110646-kardenwort-mpv\\tests\\tests\\mpv_last_run.log'
```

This is because `os.getcwd()` returns the `tests` directory when running from there, so `os.path.join(os.getcwd(), 'tests', 'mpv_last_run.log')` creates `tests/tests/`.

## Proposed Solutions

### Solution 1: Fix Test Fixture Path

```python
# In tests/ipc/mpv_session.py line 32
# Change from:
log_path = os.path.join(os.getcwd(), 'tests', 'mpv_last_run.log')
# To:
log_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'tests', 'mpv_last_run.log')
```

### Solution 2: Refine TIMESEEK_INHIBIT_UNTIL Logic

The key insight is that we need to distinguish between:

1. **Rewind within same subtitle**: Autopause should still fire at end of subtitle
2. **Rewind across subtitles**: Autopause should be suppressed during transit

Proposed approach:

```lua
local function cmd_seek_time(dir)
    -- ... accumulator logic ...
    
    local current_pos = mp.get_property_number("time-pos") or 0
    local current_idx = get_center_index(Tracks.pri.subs, current_pos)
    
    -- Clear inhibit on forward seek
    if delta > 0 then
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
    else
        -- Backward seek: track rewind state
        if not FSM.REWIND_START_IDX then
            FSM.REWIND_START_IDX = current_idx
        end
        
        -- Set inhibit to current position
        FSM.TIMESEEK_INHIBIT_UNTIL = math.max(FSM.TIMESEEK_INHIBIT_UNTIL or 0, current_pos)
    end
    
    mp.commandv("seek", delta, "relative+exact")
    -- ... OSD logic ...
end
```

Then in `tick_autopause`:

```lua
local function tick_autopause(time_pos)
    if FSM.AUTOPAUSE ~= "ON" or FSM.SPACEBAR ~= "IDLE" then return end
    if FSM.SCHEDULED_REPLAY_START or FSM.LOOP_MODE == "ON" then return end
    if FSM.MEDIA_STATE == "NO_SUBS" then return end
    
    -- Check if we're still in rewind transit
    local current_idx = get_center_index(Tracks.pri.subs, time_pos)
    local in_rewind_transit = FSM.TIMESEEK_INHIBIT_UNTIL and time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL
    
    -- Special case: within-subtitle rewind
    local within_subtitle_rewind = in_rewind_transit and 
                                 FSM.REWIND_START_IDX and 
                                 current_idx == FSM.REWIND_START_IDX
    
    -- Suppress autopause during cross-subtitle rewind transit
    if in_rewind_transit and not within_subtitle_rewind then
        return
    end
    
    -- ... rest of autopause logic ...
end
```

And in `master_tick`, clear the rewind state when transit ends:

```lua
-- Clear rewind state when transit ends
if FSM.TIMESEEK_INHIBIT_UNTIL and time_pos > FSM.TIMESEEK_INHIBIT_UNTIL then
    FSM.TIMESEEK_INHIBIT_UNTIL = nil
    FSM.REWIND_START_IDX = nil
end
```

### Solution 3: PHRASE Mode Seamless Handover During Rewind

To address the overlay/jerking issue in PHRASE mode during rewind:

```lua
local function get_effective_boundaries(subs, sub, idx)
    local pad_start = (Options.audio_padding_start or 0) / 1000
    local pad_end = (Options.audio_padding_end or 0) / 1000
    
    local start = sub.start_time - pad_start
    local stop = sub.end_time + pad_end
    
    -- Movie Mode: Seamless handover at next subtitle's padded start
    if FSM.IMMERSION_MODE == "MOVIE" and idx and subs and idx < #subs then
        stop = subs[idx + 1].start_time - pad_start
        if stop < sub.end_time then stop = sub.end_time end
    end
    
    -- [NEW] PHRASE Mode: Seamless handover during rewind transit
    if FSM.IMMERSION_MODE == "PHRASE" and FSM.TIMESEEK_INHIBIT_UNTIL and idx and subs and idx < #subs then
        stop = subs[idx + 1].start_time - pad_start
        if stop < sub.end_time then stop = sub.end_time end
    end
    
    return start, stop
end
```

This gives PHRASE mode MOVIE-like behavior during rewind transit, preventing the overlay effect.

### Solution 4: Accumulator Behavior for Rewind

From anchor 20260510170701: "It is necessary for the clicks to accumulate"

The current accumulator logic only accumulates if within the time window. For rewind, we might want different behavior:

```lua
local function cmd_seek_time(dir)
    local now = mp.get_time()
    local delta = dir * Options.seek_time_delta
    
    -- YouTube-style Accumulator logic:
    local same_dir = (dir > 0 and FSM.SEEK_ACCUMULATOR > 0) or (dir < 0 and FSM.SEEK_ACCUMULATOR < 0)
    
    -- [NEW] Extended accumulator window for rewind
    local accumulator_window = (delta < 0) and (Options.seek_osd_duration * 2) or Options.seek_osd_duration
    
    if now < FSM.SEEK_LAST_TIME + accumulator_window and same_dir then
        FSM.SEEK_ACCUMULATOR = FSM.SEEK_ACCUMULATOR + delta
        FSM.SEEK_PRESS_COUNT = FSM.SEEK_PRESS_COUNT + 1
    else
        FSM.SEEK_ACCUMULATOR = delta
        FSM.SEEK_PRESS_COUNT = 1
    end
    FSM.SEEK_LAST_TIME = now
    
    -- ... rest of function ...
end
```

This gives a longer accumulator window for backward seeks, allowing more clicks to accumulate.

## Next Steps

1. Implement Solution 1 (test fixture path fix)
2. Implement Solution 2 (refined TIMESEEK_INHIBIT_UNTIL logic)
3. Implement Solution 3 (PHRASE mode seamless handover during rewind)
4. Implement Solution 4 (extended accumulator for rewind)
5. Run tests and verify fixes
6. Update documentation
7. Archive change

## Risks and Considerations

1. **State complexity**: Adding `REWIND_START_IDX` increases state complexity
2. **Edge cases**: Need to handle edge cases like rewinding past beginning of file
3. **Performance**: Additional `get_center_index` call in `cmd_seek_time`
4. **Test coverage**: Need comprehensive tests for new behavior
5. **Backward compatibility**: Changes should be backward compatible with existing behavior
