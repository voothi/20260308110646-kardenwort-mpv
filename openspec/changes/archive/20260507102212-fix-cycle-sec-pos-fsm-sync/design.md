## Context

`FSM.native_sec_sub_pos` is the FSM desired-state field for the secondary subtitle position. It must match the actual `secondary-sub-pos` mpv property at all times so that direction-aware operations (cycle, delta adjustment) always compute from correct state.

`cmd_cycle_sec_pos` has two branches:

- **Drum ON** (lines 7443–7445): reads `FSM.native_sec_sub_pos`, writes new value to both FSM and mpv. **Correct.**
- **Drum OFF** (lines 7447–7450): reads mpv property directly, writes new value only to mpv. **Missing FSM sync.**

The `20260507090243` remediation fixed the same class of defect in `cmd_adjust_sec_sub_pos` but did not address this branch of `cmd_cycle_sec_pos`.

---

## Goals / Non-Goals

**Goals:**
- `cmd_cycle_sec_pos` non-Drum branch writes `FSM.native_sec_sub_pos` after setting the mpv property.
- `fsm-architecture` spec gains an explicit scenario for `cmd_cycle_sec_pos` toggle sync.

**Non-Goals:**
- No changes to rendering, OSD, Drum Window, or autopause logic.
- No new FSM fields, no new Options keys.
- No secondary-track sentinel tracking (separate concern).
- No property observer for `secondary-sub-pos` (out of scope).

---

## Decisions

### Decision 1 — Single write-back in the else-branch

**Problem:** The Drum OFF branch reads from `mp.get_property_number("secondary-sub-pos")` (correct — mpv owns actual position when not in Drum Mode), computes `n`, sets mpv property, but omits the FSM write-back.

**Decision:** Capture the computed value and write it to both targets:

```lua
-- Before:
local p = mp.get_property_number("secondary-sub-pos", Options.sec_pos_top)
local n = (p < 50) and Options.sec_pos_bottom or Options.sec_pos_top
mp.set_property_number("secondary-sub-pos", n)

-- After:
local p = mp.get_property_number("secondary-sub-pos", Options.sec_pos_top)
local n = (p < 50) and Options.sec_pos_bottom or Options.sec_pos_top
mp.set_property_number("secondary-sub-pos", n)
FSM.native_sec_sub_pos = n
```

This is the minimal, symmetric fix — identical pattern to what `cmd_adjust_sec_sub_pos` received in the previous remediation.

**Alternative considered:** Unify both branches into one by always reading from mpv property. Rejected — the Drum branch reads FSM (not mpv) because mpv's `secondary-sub-pos` is not updated when Drum Mode renders an OSD overlay at a computed position; FSM is the authoritative source in that case. Diverging branch logic is intentional; the fix is to add the missing write-back, not to merge the branches.

### Decision 2 — Spec delta: add scenario to fsm-architecture

The `fsm-architecture` spec already states the invariant ("FSM.native_sec_sub_pos SHALL be kept synchronized at all times") but only has a concrete scenario for `cmd_adjust_sec_sub_pos`. Adding an explicit scenario for `cmd_cycle_sec_pos` makes the requirement unambiguous for both write paths and prevents the same gap from reappearing.

---

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| One FSM write added per Shift+X press in non-Drum mode | Negligible: one number assignment, no table allocation, no rendering cost |
| Divergence if mpv changes `secondary-sub-pos` externally (e.g. native `j` key) | Out of scope for this change; no property observer is currently in use — the existing architecture accepts this |

## Migration Plan

No migration. In-place correction to one existing function and one spec file. No data format changes.
