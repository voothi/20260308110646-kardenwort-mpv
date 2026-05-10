# Tasks: Fix 5 Failing Tests

**ZID**: 20260510125327
**Date**: 2026-05-10

## Task 1: Update `get_effective_boundaries` function signature

**File:** `scripts/lls_core.lua`
**Line:** ~667

**Description:**
Change the function signature from `get_effective_boundaries(sub, idx)` to `get_effective_boundaries(subs, sub, idx)` to support both primary and secondary subtitle tracks.

**Steps:**
1. Find the `get_effective_boundaries` function definition (around line 667)
2. Change the signature from `local function get_effective_boundaries(sub, idx)` to `local function get_effective_boundaries(subs, sub, idx)`
3. Remove the line `local subs = Tracks.pri.subs` (it's no longer needed)
4. Verify the function uses the passed `subs` parameter instead of `Tracks.pri.subs`

**Verification:**
- Function signature accepts `subs` as first parameter
- Function no longer hardcodes `Tracks.pri.subs`

---

## Task 2: Update all calls to `get_effective_boundaries`

**File:** `scripts/lls_core.lua`
**Lines:** Multiple locations

**Description:**
Update all calls to `get_effective_boundaries` to pass the `subs` parameter.

**Locations to update:**
1. Line ~704: `get_effective_boundaries(subs[active_idx], active_idx)` → `get_effective_boundaries(subs, subs[active_idx], active_idx)`
2. Line ~716: `get_effective_boundaries(subs[next_idx], next_idx)` → `get_effective_boundaries(subs, subs[next_idx], next_idx)`
3. Line ~745: `get_effective_boundaries(next_sub, best + 1)` → `get_effective_boundaries(subs, next_sub, best + 1)`
4. Line ~758: `get_effective_boundaries(next_sub)` → `get_effective_boundaries(subs, next_sub)`
5. Line ~5094: `get_effective_boundaries(sub, line_idx)` → `get_effective_boundaries(subs, sub, line_idx)`
6. Line ~5251: `get_effective_boundaries(subs[active_idx], active_idx)` → `get_effective_boundaries(subs, subs[active_idx], active_idx)`
7. Line ~5412: `get_effective_boundaries(Tracks.pri.subs[active_idx], active_idx)` → `get_effective_boundaries(Tracks.pri.subs, Tracks.pri.subs[active_idx], active_idx)`
8. Line ~6153: `get_effective_boundaries(sub, FSM.DW_CURSOR_LINE)` → `get_effective_boundaries(Tracks.pri.subs, sub, FSM.DW_CURSOR_LINE)`
9. Line ~6203: `get_effective_boundaries(sub, target_idx)` → `get_effective_boundaries(Tracks.pri.subs, sub, target_idx)`

**Verification:**
- All calls to `get_effective_boundaries` pass 3 arguments (or 2 if idx is optional)
- No calls use the old 2-argument signature

---

## Task 3: Restore Natural Progression expiry check

**File:** `scripts/lls_core.lua`
**Lines:** ~710-720

**Description:**
Add the missing expiry check that ensures we only transition to the next sub after the current sub's padded window expires.

**Steps:**
1. Find the Natural Progression logic in `get_center_index` (around line 710)
2. Update the condition to include the expiry check:
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

**Verification:**
- Natural Progression checks if current sub's padded window has expired before transitioning
- Test `test_20260501005019_natural_progression` passes
- Test `test_20260506223500_natural_progression_skip` passes
- Test `test_phrase_jerkback_advances_active_idx_in_overlap` passes

---

## Task 4: Add Overlap Priority guard

**File:** `scripts/lls_core.lua`
**Lines:** ~743-749

**Description:**
Add the guard that only applies Overlap Priority when `time_pos > subs[best].end_time`.

**Steps:**
1. Find the Overlap Priority logic in `get_center_index` (around line 743)
2. Update the condition to include the guard:
   ```lua
   if best < #subs and time_pos > subs[best].end_time then
       local next_sub = subs[best + 1]
       local s_next, _ = get_effective_boundaries(subs, next_sub, best + 1)
       if time_pos >= s_next - Options.nav_tolerance then
           return best + 1
       end
   end
   ```

**Verification:**
- Overlap Priority only applies when past the current sub's actual SRT end time
- No regressions in existing tests

---

## Task 5: Fix double-click cursor clearing

**File:** `scripts/lls_core.lua`
**Lines:** ~5085-5100

**Description:**
Investigate and fix why `dw_cursor['word']` is not being set to -1 after double-click.

**Steps:**
1. Find the `cmd_dw_double_click` function (around line 5085)
2. Check if the function properly clears `FSM.DW_CURSOR_WORD` (or `dw_cursor['word']`)
3. Add cursor clearing if missing:
   ```lua
   FSM.DW_CURSOR_WORD = -1  -- Clear cursor word index
   ```

**Verification:**
- Test `test_dw_mouse_selection_engine_double_click` passes
- `dw_cursor['word']` is -1 after double-click

---

## Task 6: Fix OSD rendering after seek

**File:** `scripts/lls_core.lua`
**Lines:** Multiple locations

**Description:**
Investigate and fix why drum OSD returns empty render after seek.

**Steps:**
1. Check the tooltip pre-loading logic in `update_media_state` (around line 3123)
2. Verify that `FSM.DW_TOOLTIP_SEC_SUBS` is properly populated
3. Check the secondary subtitle visibility logic in `cmd_cycle_sec_sid` (around line 7561)
4. Verify that the drum window rendering logic properly handles the tooltip cache
5. Add defensive checks to ensure OSD is not empty after seek

**Verification:**
- Test `test_has_phrase_phrase_first_order` passes
- Drum OSD returns non-empty render after seek

---

## Task 7: Run tests to verify all fixes

**Command:** `pytest tests/acceptance/test_20260501160807_dw_esc_staged_reset.py::TestImmersionRegressions::test_20260501005019_natural_progression -v`

**Description:**
Run the specific failing tests to verify they now pass.

**Steps:**
1. Run test 1: `pytest tests/acceptance/test_20260501160807_dw_esc_staged_reset.py::TestImmersionRegressions::test_20260501005019_natural_progression -v`
2. Run test 2: `pytest tests/acceptance/test_20260506223500_fixtures_load.py::test_20260506223500_natural_progression_skip -v`
3. Run test 3: `pytest tests/acceptance/test_20260509080221_drum_window_indexing_simple.py::TestHistoricalRegressionsV2::test_dw_mouse_selection_engine_double_click -v`
4. Run test 4: `pytest tests/acceptance/test_20260509085125_has_phrase_phrase_first.py::test_has_phrase_phrase_first_order -v`
5. Run test 5: `pytest tests/acceptance/test_20260509085150_cycle_never_lands_on.py::TestImmersionSuiteHardening::test_phrase_jerkback_advances_active_idx_in_overlap -v`
6. Run full test suite: `pytest tests/acceptance/ -v`

**Verification:**
- All 5 previously failing tests now pass
- No regressions in other tests
- Total test count: 658 passed (653 + 5 fixed)

---

## Task 8: Update documentation

**Files:** Multiple

**Description:**
Update any relevant documentation to reflect the changes.

**Steps:**
1. Check if `openspec/specs/immersion-engine/spec.md` needs updates
2. Check if any other specs need updates
3. Update `docs/conversation.log` with the fix details

**Verification:**
- Documentation is accurate and up-to-date

---

## Task 9: Archive the change

**Command:** `/opsx:archive`

**Description:**
Archive the change after all fixes are verified.

**Steps:**
1. Ensure all tasks are complete
2. Run `/opsx:archive` to archive the change
3. Verify the change is in `openspec/changes/archive/`

**Verification:**
- Change is archived successfully
- All artifacts are in the archive
