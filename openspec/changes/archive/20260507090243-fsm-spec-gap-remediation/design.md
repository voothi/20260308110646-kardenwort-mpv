## Context

Three correctness gaps identified in audit ZID 20260507082627. All are state-management defects invisible at runtime until edge conditions are hit. The codebase is currently in a stable visual state; all fixes must be zero-visual-impact.

**Current code state (HEAD, post-v1.58.50):**

- `cmd_toggle_sub_vis` (line 7415): guards on `DRUM_WINDOW ~= "OFF"` and returns without updating `FSM.native_sub_vis`. After dismissing DW, the FSM carries the wrong desired-state.
- `get_center_index` (line 680): reads `FSM.ACTIVE_IDX` as the sentinel regardless of which track's subtitle array is passed. For secondary-track calls, this index may address a different (or non-existent) subtitle.
- `cmd_adjust_sec_sub_pos` (line 7466): updates mpv's `secondary-sub-pos` property but does not write back to `FSM.native_sec_sub_pos`, leaving the FSM desired-state stale. `cmd_cycle_sec_pos` (line 7436) reads this field in Drum Mode to decide toggle direction, so drift causes incorrect toggling.

---

## Goals / Non-Goals

**Goals:**
- `cmd_toggle_sub_vis` updates `FSM.native_sub_vis` uniformly regardless of active mode.
- `get_center_index` uses the sentinel only when resolving the primary track; secondary calls get no (wrong) sentinel.
- `cmd_adjust_sec_sub_pos` keeps `FSM.native_sec_sub_pos` in sync after every property write.

**Non-Goals:**
- No changes to OSD rendering, DW layout, drum rendering, highlighting, or autopause.
- No new FSM fields, no new Options keys.
- No change to `tick_dw`, `tick_drum`, `master_tick`, or `get_effective_boundaries`.
- No handling of secondary-track sentinel tracking (a separate, larger concern).

---

## Decisions

### Decision 1 — `cmd_toggle_sub_vis`: remove guard, preserve DW visual output

**Problem:** When DW is open, `tick_dw` renders `dw_osd` unconditionally — it does not check `FSM.native_sub_vis`. Native subs are already suppressed by `dw_active = true` in `master_tick`. So the DW window's visual output is entirely independent of `FSM.native_sub_vis`.

**Decision:** Remove the `DRUM_WINDOW ~= "OFF"` early-return. The rest of the function is unchanged. The call to `master_tick()` at the end handles all side effects.

**Trace when DW open after fix:**
```
user presses 's' while DW is DOCKED
→ FSM.native_sub_vis toggled
→ FSM.native_sec_sub_vis toggled
→ master_tick() called
→ dw_active = true
→ target_pri_vis = false  (not dw_active always wins)
→ target_sec_vis = false  (same)
→ tick_dw() called → dw_osd renders (unchanged — does not read native_sub_vis)
→ drum_osd cleared (same as before)
```
Visual result: **identical to current behavior**. The DW window is unaffected. When the user later closes DW, `FSM.native_sub_vis` correctly reflects the toggle.

**Alternative considered:** Keep the guard but also update FSM state before returning. Rejected — the guard becomes misleading dead code. Removing it is cleaner.

**OSD message:** The function shows "Subtitles: ON/OFF" as usual. While DW is open this is a correct and useful status message (it tells the user what will happen when they return to normal mode).

---

### Decision 2 — `get_center_index`: table-reference sentinel guard

**Problem:** `FSM.ACTIVE_IDX` is the primary-track sentinel. When called with `Tracks.sec.subs`, the sentinel is a primary-track index used to address a secondary-track array — potentially out-of-bounds (silently nil-guarded) or semantically incorrect.

**Decision:** One-line guard using Lua table reference equality:

```lua
-- Before:
local active_idx = FSM.ACTIVE_IDX

-- After:
local active_idx = (subs == Tracks.pri.subs) and FSM.ACTIVE_IDX or -1
```

Lua `==` on tables compares references. `Tracks.pri.subs` and `Tracks.sec.subs` are always distinct table objects (assigned independently in `update_media_state`). When `subs` is the secondary array, `active_idx = -1`, bypassing all sentinel logic and falling through to binary search — which is correct and was the behavior before the sentinel was introduced.

**Why this over adding a parameter:** Zero call-site changes, zero new state, one changed line. The reference identity of `Tracks.pri.subs` is stable for the lifetime of any single `get_center_index` call (Lua is single-threaded; the table is only reassigned in `update_media_state` which is event-driven, not in-tick).

**Jerk-Back interaction:** When `PHRASE` mode and `JUST_JERKED_TO ~= -1`, `active_idx` is overridden to `JUST_JERKED_TO`. With the guard, this override only applies for primary-track calls (the override is inside the jerk-back branch which reads `FSM.IMMERSION_MODE`, always meaningful for primary). Secondary calls get `active_idx = -1` and skip both the sentinel and the jerk-back override — correct behavior.

**Alternative considered:** Add optional `sentinel` parameter. Rejected — requires updating ~8 primary-track call sites with `FSM.ACTIVE_IDX` explicitly, adding noise without correctness benefit.

---

### Decision 3 — `cmd_adjust_sec_sub_pos`: write-back after property set

**Problem:** `cmd_adjust_sec_sub_pos` reads `secondary-sub-pos` from mpv, clamps, and writes back to mpv — but never updates `FSM.native_sec_sub_pos`. `cmd_cycle_sec_pos` in Drum Mode reads `FSM.native_sec_sub_pos < 50` to decide direction. If the user adjusts via delta while not in Drum Mode, then enters Drum Mode and cycles, the direction can be wrong.

**Decision:** Capture the computed value in a local, write to both mpv and FSM:

```lua
local p = mp.get_property_number("secondary-sub-pos", 10)
local new_pos = math.max(0, math.min(150, p + delta))
mp.set_property_number("secondary-sub-pos", new_pos)
FSM.native_sec_sub_pos = new_pos
```

The `< 50` threshold in `cmd_cycle_sec_pos` is correct: values below 50 are in the top half of the screen (mpv's `secondary-sub-pos` scale). The sync ensures this toggle direction is always computed from actual position.

**`cmd_adjust_sub_pos` note:** The primary equivalent (`cmd_adjust_sub_pos`) does not have an `FSM.native_sub_pos` field — primary position is not tracked in FSM desired-state. No change needed there.

---

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| `cmd_toggle_sub_vis` with DW open shows "Subtitles: OFF" OSD while DW content is still visible — could be confusing | Acceptable: the message is accurate about *native/OSD* state; DW is a separate surface. Consistent with how Drum Mode works. |
| Table-reference guard in `get_center_index` is an implicit contract on `Tracks.pri.subs` identity | The reference is only replaced in `update_media_state` (event-driven, never mid-tick). Risk is theoretical. If future refactoring passes a copy of `pri.subs`, the sentinel would be disabled — degraded-but-safe behavior. |
| `FSM.native_sec_sub_pos` sync adds one FSM write per delta key press | Negligible: one number assignment, no table allocation, no rendering cost. |

## Migration Plan

No migration needed. All changes are in-place corrections to existing functions. No data format changes, no Options changes, no new event handlers.

## Open Questions

_(none — all decisions are self-contained)_
