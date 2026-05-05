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

### 1. Cyclic Indexing Logic
Instead of `math.max/min`, we will use a modulo-like approach in `cmd_dw_seek_delta`:
```lua
local target_idx = base_idx + dir
if target_idx < 1 then target_idx = #subs
elseif target_idx > #subs then target_idx = 1 end
```
This ensures that `a` at sub 1 goes to sub `#subs`, and `d` at sub `#subs` goes to sub 1.

### 2. Boundary Hardening in master_tick
I will audit the "Jerk Back" logic and `get_center_index` to ensure that transitions at the start of the file are stable. Specifically, I will ensure `FSM.ACTIVE_IDX` is properly initialized or synchronized when seeking to the start.

### 3. OSD Feedback
I'll ensure the OSD message indicates when a wrap-around has occurred (e.g., "Seeking to Last Subtitle" or "Seeking to First Subtitle").

## Risks / Trade-offs
- **Cyclic Confusion**: Users accustomed to clamping might be surprised, but this is the requested behavior.
- **Short Tracks**: For tracks with very few subtitles, cyclic navigation might feel jumpy.
