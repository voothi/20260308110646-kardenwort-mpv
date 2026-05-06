# Tasks: Natural Progression Sub-Skip Fix

## 1. Core FSM Fix

- [x] 1.1 Insert **One-step Natural Progression** check in `get_center_index` (`lls_core.lua`) between the sticky sentinel check and the binary search block.
  - Check: `if ACTIVE_IDX+1`'s padded zone contains `time_pos` → return `ACTIVE_IDX+1`.
  - Guard: `time_pos <= e_next` to preserve MOVIE mode gapless handover.
  - Revert any prior incorrect fixes (`seek_target = max(...)`, `MANUAL_NAV_COOLDOWN` in `cmd_smart_space`).

## 2. Specification Update

- [x] 2.1 Add delta spec to `immersion_engine` strengthening the "transition to i+1" requirement with explicit language about large-padding overlap scenarios and the Natural Progression check.

## 3. FSM Diagram Update

- [x] 3.1 Update state transition diagram in `design.md` to include `NATURAL_PROGRESSION` as a named state between `STICKY_LOCK` and `SUB_LOCKED`, documenting it as a canonical step in the FSM.
