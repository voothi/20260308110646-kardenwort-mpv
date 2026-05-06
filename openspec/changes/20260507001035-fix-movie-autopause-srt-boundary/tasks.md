# Tasks: MOVIE Mode Autopause SRT Boundary Compliance Fix

**Change ID:** 20260507001035-fix-movie-autopause-srt-boundary  
**Estimated Duration:** 45 minutes  
**Complexity:** Very Low  

---

## Task 1: Code Modification — Guard Condition Update

**Objective:** Modify the boundary enforcement guard condition to enforce SRT boundary compliance

**Duration:** 10 minutes

### 1.1 Precondition Verification

- [ ] Clone/open repository at: `u:\voothi\20260308110646-kardenwort-mpv\`
- [ ] Verify Lua development environment available (editor with syntax highlighting)
- [ ] Confirm `scripts/lls_core.lua` is accessible

### 1.2 Locate Target Section

**File:** `scripts/lls_core.lua`  
**Function:** `get_effective_boundaries(sub, idx)`  
**Search Pattern:** `if stop < start then stop = sub.end_time end`

**Navigation Steps:**
1. Open file `scripts/lls_core.lua`
2. Navigate to line 674 (use Ctrl+G or equivalent goto-line function)
3. Verify you are within the `get_effective_boundaries()` function (lines 660–678)
4. Confirm the guard condition is exactly as documented:
   ```lua
   -- Guard against stop being before start (extreme overlaps)
   if stop < start then stop = sub.end_time end
   ```

### 1.3 Execute Modification

**Change Type:** String replacement (exact)

**Original Text (3 lines):**
```lua
        -- Guard against stop being before start (extreme overlaps)
        if stop < start then stop = sub.end_time end
```

**New Text (3 lines):**
```lua
        -- Guard: never pause before SRT end_time (short gaps shrink the handover boundary)
        if stop < sub.end_time then stop = sub.end_time end
```

**Modification Checklist:**
- [ ] Line 673: Comment text changed completely
- [ ] Line 674: Predicate changed from `stop < start` to `stop < sub.end_time`
- [ ] Line 675: Unchanged (still `end`)
- [ ] Indentation: 8 spaces (preserved from context)
- [ ] No additional lines added or removed

### 1.4 Syntax Validation

After modification:

1. **Visual Inspection:**
   - [ ] Lua syntax highlighting shows no errors
   - [ ] Parentheses/brackets balanced
   - [ ] Comment syntax correct (`--` prefix)

2. **Optional: Lua Parser Check** (if available):
   ```bash
   lua -c scripts/lls_core.lua
   ```
   - [ ] Parser reports no syntax errors

### 1.5 Contextual Review

Verify the modification is in the correct location by examining surrounding context:

**Lines 665–678 Should Show:**
```lua
    local start = sub.start_time - pad_start
    local stop = sub.end_time + pad_end
    
    -- [v1.58.51] Movie Mode: Seamless handover at the next subtitle's padded start.
    -- This prevents overlapping audio loops while still ensuring the pre-roll is heard.
    if FSM.IMMERSION_MODE == "MOVIE" and idx and subs and idx < #subs then
        stop = subs[idx + 1].start_time - pad_start
        -- Guard: never pause before SRT end_time (short gaps shrink the handover boundary)
        if stop < sub.end_time then stop = sub.end_time end
    end
    
    return start, stop
```

- [ ] Context matches expected structure
- [ ] MOVIE mode conditional intact
- [ ] Return statement at line 677 correct

### 1.6 Save and Confirm

- [ ] File saved to disk: `scripts/lls_core.lua`
- [ ] File modification timestamp updated
- [ ] No backup or temporary files left behind

---

## Task 2: Functional Verification — Small Gap Scenario

**Objective:** Verify that subtitles with small inter-subtitle gaps now play to completion without truncation

**Duration:** 15 minutes

### 2.1 Test Environment Setup

**Preconditions:**
- [ ] mpv player installed and functional
- [ ] Project configuration (`mpv.conf`) accessible
- [ ] Lua scripts reloaded (via mpv reload or restart)
- [ ] Test subtitle file available

**Test Subtitle File Requirements:**
- Contains at least 3 consecutive subtitles
- Subtitles 1 and 2 separated by 100–200ms gap (small gap)
- Subtitles 2 and 3 separated by 500ms+ gap (large gap for control)
- Audio file with corresponding timing

**Alternative:** Create minimal test SRT:
```
1
00:00:00,000 --> 00:00:01,000
Test subtitle one

2
00:00:01,100 --> 00:00:02,000
Test subtitle two

3
00:00:02,600 --> 00:00:03,000
Test subtitle three
```

### 2.2 Configuration Verification

**Precondition Checks:**
- [ ] MOVIE mode enabled: Verify `FSM.IMMERSION_MODE == "MOVIE"`
  - Toggle via `O` or `Щ` key binding if needed
- [ ] Autopause enabled: `FSM.AUTOPAUSE == "ON"`
  - Toggle via `S` or `Ы` key binding if needed
- [ ] Karaoke mode disabled (no mid-phrase pause prevention interference)

### 2.3 Playback Observation — Small Gap Subtitle

**Test Case: Subtitle 1 (Small gap before Subtitle 2)**

**Setup:**
1. Load video/audio with test SRT
2. Ensure MOVIE mode and autopause active
3. Navigate to subtitle 1 (00:00:00)
4. Position playhead slightly before subtitle 1 end (00:00:00.950)

**Observation Procedure:**
1. Press play or spacebar to resume
2. Allow playback to proceed naturally toward subtitle 1 end
3. Observe exact pause point timing
4. Note whether full audio of subtitle 1 is heard before pause

**Expected Results:**
- Playhead pauses at or near 00:00:01.000 (subtitle 1 `end_time`)
- All audio content of subtitle 1 is fully audible
- Pause occurs within lookahead buffer (pause_padding = 0.15s)
- Acceptable range: 00:00:00.850 to 00:00:01.000

**Pass Criteria:**
- [ ] Subtitle 1 audio plays to completion
- [ ] Pause occurs within acceptable window
- [ ] No truncation of final audio segment

**Failure Indicators:**
- ✗ Pause occurs before 00:00:00.850 (premature)
- ✗ Audio clearly truncated at subtitle end
- ✗ Pause occurs in silent gap (indicates boundary incorrectness)

### 2.4 Regression Test — Large Gap Scenario

**Test Case: Subtitle 2 → Subtitle 3 (Large gap, seamless handover control)**

**Setup:**
1. Position playhead at start of subtitle 2 (00:00:01.100)
2. MOVIE mode and autopause remain active

**Observation Procedure:**
1. Allow playback to proceed through subtitle 2 and into gap
2. Observe pause behavior after subtitle 2 end
3. Note pause point relative to subtitle 3 start

**Expected Results:**
- Pause occurs in gap between subtitles (seamless handover region)
- Pause point approximately: `subtitle_3_start - audio_padding_start` ≈ 00:00:02.400
- Subtitle 3 audio is not prematurely truncated

**Pass Criteria:**
- [ ] Seamless handover occurs as designed
- [ ] Pause between gap region (not cutting into subtitle 2 or 3)
- [ ] No regression in cinematic flow

### 2.5 Documentation of Results

**Record Observations:**

```
Test Case 1 (Small Gap):
- Subtitle 1 end_time: 00:00:01.000
- Subtitle 2 start_time: 00:00:01.100
- Observed pause point: [HH:MM:SS.MMM]
- Audio truncation?: [Yes/No]
- Status: [PASS/FAIL]

Test Case 2 (Large Gap):
- Subtitle 2 end_time: 00:00:02.000
- Subtitle 3 start_time: 00:00:02.600
- Observed pause point: [HH:MM:SS.MMM]
- Seamless handover intact?: [Yes/No]
- Status: [PASS/FAIL]
```

---

## Task 3: Code Review — Contextual Validation

**Objective:** Conduct peer review of the modification to ensure correctness and no unintended consequences

**Duration:** 10 minutes

### 3.1 Self-Review Checklist

**Review the modification in context:**

- [ ] **Semantics:** Guard condition logic is correct
  - Predicate `stop < sub.end_time` correctly identifies undershooting boundary
  - Fallback to `sub.end_time` is appropriate remedy
  
- [ ] **No Unintended Side Effects:**
  - Guard only affects MOVIE mode (gated by `if FSM.IMMERSION_MODE == "MOVIE"`)
  - PHRASE mode unaffected (uses original `sub.end_time + pad_end`)
  - Function return value still a valid (start, stop) tuple
  
- [ ] **Invariant Preservation:**
  - After change: `stop ≥ sub.end_time` (at minimum)
  - Before change: only `stop ≥ start` was guaranteed
  - New invariant is stricter and more correct
  
- [ ] **Performance:**
  - Single conditional comparison (no loops, no allocations)
  - Negligible computational cost
  - No impact on event loop timing

### 3.2 Regression Impact Analysis

Examine potential impacts on dependent code:

**Function:** `tick_autopause()` (line 5179)
- [ ] Uses return value: `local _, sub_end = get_effective_boundaries(...)`
- [ ] With new guard: `sub_end` may be higher than before (less undershooting)
- [ ] Effect: Pause may fire slightly later (more correct)
- [ ] Risk: None identified

**Function:** `get_center_index()` (line 680)
- [ ] Uses return value: `local s, e = get_effective_boundaries(...)`
- [ ] With new guard: `e` may be higher than before
- [ ] Effect: Active subtitle focus window slightly extended backward
- [ ] Risk: Could theoretically extend overlap with previous subtitle; mitigated by Sticky Focus Sentinel and Natural Progression logic
- [ ] Conclusion: No practical impact; focus logic remains sound

### 3.3 Documentation Review

- [ ] Comment update reflects new semantics: "never pause before SRT end_time (short gaps shrink the handover boundary)"
- [ ] Comment accurately describes the invariant enforcement
- [ ] No misleading or incorrect documentation

### 3.4 Sign-Off

- [ ] Code change is minimal and focused
- [ ] Logic is sound and mathematically correct
- [ ] No side effects or regressions identified
- [ ] Ready for testing

---

## Task 4: Integration Testing — Full Immersion Mode Suite

**Objective:** Verify behavior across all immersion modes and autopause variations

**Duration:** 10 minutes

### 4.1 PHRASE Mode Regression Test

**Precondition:**
- [ ] Toggle to PHRASE mode (press `O` or `Щ`)
- [ ] Load test SRT with small gaps
- [ ] Autopause enabled

**Observation:**
1. Play subtitle with small gap following
2. Observe pause point

**Expected Behavior:**
- PHRASE mode unchanged (uses `sub.end_time + pad_end`)
- Pause point should reflect audio_padding_end (200ms after SRT end)
- No changes from pre-fix behavior

**Pass Criteria:**
- [ ] Pause timing unchanged from baseline PHRASE behavior
- [ ] audio_padding_end respected (pause at ~sub.end_time + 0.2s)

### 4.2 Autopause Toggle Verification

**Precondition:**
- [ ] MOVIE mode enabled
- [ ] Autopause currently ON

**Test Sequence:**
1. Play through subtitle with small gap
2. Observe pause fires (autopause active)
3. Toggle autopause OFF (press `S` or `Ы`)
4. Play through another subtitle
5. Observe no pause occurs (autopause inactive)
6. Toggle autopause back ON
7. Play through subtitle again
8. Observe pause fires (autopause re-enabled)

**Pass Criteria:**
- [ ] Autopause toggles correctly
- [ ] Pause behavior follows toggle state
- [ ] No side effects from modified guard

### 4.3 Scheduled Replay Mode Check

**Precondition:**
- [ ] MOVIE mode and autopause enabled
- [ ] Familiar with replay key binding (if configured)

**Test:** (Optional if replay mode available)
1. Select subtitle range for replay
2. Enter scheduled replay mode
3. Observe autopause behavior during replay

**Expected:** Autopause should be suppressed during replay (per line 5181 of lls_core.lua)

**Pass Criteria:**
- [ ] Replay mode functions normally
- [ ] Autopause correctly suppressed during replay
- [ ] No interference from boundary modification

---

## Task 5: Final Verification and Sign-Off

**Objective:** Confirm all tests passed and code is ready for deployment

**Duration:** 5 minutes

### 5.1 Test Summary

**Compile Results from All Tasks:**

| Test Case | Status | Notes |
|-----------|--------|-------|
| Small gap boundary (Task 2.3) | PASS / FAIL | — |
| Large gap regression (Task 2.4) | PASS / FAIL | — |
| Code review (Task 3) | PASS / FAIL | — |
| PHRASE mode regression (Task 4.1) | PASS / FAIL | — |
| Autopause toggle (Task 4.2) | PASS / FAIL | — |
| Replay mode (Task 4.3) | PASS / FAIL | Optional |

**Overall Status:**
- [ ] All mandatory tests: **PASS**
- [ ] No regressions identified
- [ ] Code ready for production

### 5.2 Deployment Checklist

Before marking complete:

- [ ] Code modification saved to `scripts/lls_core.lua` (line 674)
- [ ] Modification syntax verified (no Lua errors)
- [ ] Functional tests executed and passed
- [ ] Regression tests confirm no side effects
- [ ] Documentation (proposal, design, tasks) complete and accurate
- [ ] All test results documented above

### 5.3 Deployment Instructions

To deploy this fix:

1. **Method A (File Update):**
   - Replace `scripts/lls_core.lua` with modified version
   - Restart mpv or reload Lua scripts

2. **Method B (Manual Patch):**
   - Open `scripts/lls_core.lua` at line 674
   - Apply single-line guard condition change
   - Save and reload

### 5.4 Sign-Off

| Role | Date | Status |
|------|------|--------|
| Implementer | — | [ ] |
| QA Lead | — | [ ] |
| Release Manager | — | [ ] |

---

## Appendix A: Troubleshooting

### Issue: Tests show no change in pause behavior

**Diagnosis:**
- Lua scripts may not be reloaded
- MOVIE mode may not be active
- Autopause may be disabled

**Resolution:**
1. Confirm MOVIE mode active (press `O`/`Щ` once; should show "MOVIE" mode)
2. Confirm autopause active (press `S`/`Ы`; should show "ON")
3. Fully restart mpv player
4. Verify modification saved to file system

### Issue: Subtitle still truncated after fix

**Diagnosis:**
- Modification not applied correctly
- Lua file not reloaded
- Different code path executing

**Resolution:**
1. Verify modification at line 674 matches specification exactly
2. Check file modification timestamp (should be recent)
3. Add debug log statement to verify code path:
   ```lua
   if stop < sub.end_time then
       print("DEBUG: Clamping stop from " .. stop .. " to " .. sub.end_time)
       stop = sub.end_time
   end
   ```
4. Reload scripts and retest
5. Check mpv console output for debug message

### Issue: Pause timing off by more than 0.15s

**Diagnosis:**
- Pause_padding value may be different
- Time measurement methodology may be inconsistent

**Resolution:**
1. Verify `pause_padding` value in lls_core.lua (line 199): should be 0.15
2. Use mpv OSD timer for accurate timing (`TAB` key shows timestamp)
3. Account for event loop latency (~50ms typical)

---

## Appendix B: Configuration Reference

**Relevant Configuration Values (Read-Only for this task):**

```lua
-- lls_core.lua
pause_padding = 0.15              -- line 199
audio_padding_start = 200         -- line 470 (milliseconds)
audio_padding_end = 200           -- line 471 (milliseconds)
immersion_mode_default = "PHRASE" -- line 477

-- mpv.conf
script-opts-append=lls-autopause_default=yes
script-opts-append=lls-immersion_mode_default=PHRASE
```

No configuration changes required for this fix.

