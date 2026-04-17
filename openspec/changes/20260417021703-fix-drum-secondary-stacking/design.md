## Context
Rendering two "Drums" simultaneously (primary and secondary) at the bottom of the screen currently results in overlap because the script forces a single-block-height offset that doesn't respect the actual height of the primary drum.

## Goals / Non-Goals
**Goals:**
- Restore functionality of `r` / `t` keys for manual subtitle positioning.
- Prevent merge/overlap of tracks by default.

**Non-Goals:**
- Implementing a complex physics-based collision engine for OSD text.

## Decisions

### 1. Remove Mandatory Stacking Override
In `scripts/lls_core.lua` inside `tick_drum`, the logic that forces `sec_pos = pri_pos - delta` will be removed. Instead, the function will strictly use the positions returned by `mp.get_property_number`.

### 2. Update Default Spacing
`Options.sec_pos_bottom` will be updated to `75` (down from `90`). Since `sub-pos` defaults to `95`, this provides a 20% vertical gap, which is sufficient for two 15-line context windows without merging.

### 3. Coordinate Sync
Ensure that `cmd_cycle_sec_pos` (bound to `y`) sets the position to these improved defaults.

## Risks / Trade-offs
Users who preferred the automatic "attachment" behavior might now have to adjust their positions manually once, but they gain the flexibility to place subtitles anywhere on the screen, which is the standard mpv behavior.
