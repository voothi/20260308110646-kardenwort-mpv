# Design: Cyclic Subtitle Navigation and Boundary Hardening

## Context
The current navigation logic in `cmd_dw_seek_delta` uses `math.max(1, math.min(#subs, base_idx + dir))` which hard-clamps the index. The user wants this to wrap around. Furthermore, "Phrases" mode introduced "Jerk Back" logic in `master_tick` which might be misfiring when `active_idx` is at the beginning of the track.

## Goals / Non-Goals

**Goals:**
- Implement cyclic wrap-around for subtitle navigation in `cmd_dw_seek_delta`.
- Investigate and fix the unintended jump from the first subtitle to the last.
- Ensure OSD feedback reflects the navigation state.

**Non-Goals:**
- Changing the seek behavior for other modes (like non-immersion modes) unless necessary.
- Changing the keybindings in `input.conf`.

## Decisions

### 1. Modulo-Based Cyclic Indexing
Instead of manual clamping or branching, we use a standard 1-based modulo wrap:
```lua
local target_idx = ((base_idx + dir - 1) % #subs) + 1
```
This handles all edge cases (single sub tracks, large jumps) consistently.

### 2. Boundary and Seek Hardening
- **Negative Seek Guard**: Added `math.max(0, s)` to ensure that audio padding at the very start of the file does not result in invalid negative seek timestamps.
- **Absolute Start Guard**: Updated `get_center_index` to return index `1` if `time_pos <= 0` to stabilize the engine during loops or manual seeks to the beginning.

### 3. OSC and Manual Seek Synchronization
Hardened the **Universal Manual Seek Detection** in `master_tick` to set `FSM.MANUAL_NAV_COOLDOWN` whenever a significant jump (>0.3s) is detected. This ensures that clicking the `mpv` OSC timeline or using native seek keys correctly suppresses the Phrases mode "Jerk Back" logic, allowing the state machine to settle at the new location.

### 4. Jerk-Back Safety Jump Limit
Restricted the Phrase Mode "Jerk Back" to only trigger if the jump is within 5 subtitles (`active_idx <= FSM.ACTIVE_IDX + 5`). This prevents glitchy jumps to the end of the track from triggering a lock-on, while still allowing natural sequential navigation to benefit from padded start alignment.

## Risks / Trade-offs
- **Cyclic Confusion**: Users accustomed to clamping might be surprised, but this is the requested behavior.
- **Short Tracks**: For tracks with very few subtitles, cyclic navigation might feel jumpy.
