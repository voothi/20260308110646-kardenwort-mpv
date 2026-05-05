# Design: Audio Padding Sentinel (ZID: 20260505021903)

## Context
The project `kardenwort-mpv` uses a heartbeat loop (`master_tick`) to handle automation like autopausing and visual highlighting. Currently, this loop uses `get_center_index` to find the subtitle closest to the current playback position. When users set padding to hear audio tails, the player enters a gap between subtitles. In this gap, the index lookup often snaps to the next subtitle before the previous one's padding has finished, leading to missed automation triggers.

## Goals / Non-Goals

**Goals:**
- **Zero-Drop Autopause**: Ensure that every subtitle's end-pause triggers correctly, even with large padding values.
- **Unified Logic**: Sync seeking, autopausing, and visual highlighting to the same padded boundaries.
- **State Stability**: Prevent the script from "forgetting" its current context during the padding window.

**Non-Goals:**
- Changing the `mpv` internal subtitle rendering.
- Modifying the Anki export logic.

## Decisions

### 1. Unified Padding Options
Add `audio_padding_start` and `audio_padding_end` to the `Options` table. These will be defined in milliseconds for user convenience and converted to seconds internally.
- **Rationale**: ms is the standard for audio-visual synchronization offsets.

### 2. The "State-Locked" Sentinel
Introduce `FSM.active_idx` to track the subtitle currently "in focus". 
- **Persistence**: Once an index is set, it is held until:
  - `time_pos > sub.end + padding_end`
  - `time_pos < sub.start - padding_start` (due to manual backward seek)
  - A significant jump (>0.5s) occurs.
- **Rationale**: This eliminates the "Context Hijacking" where a new subtitle onset steals the focus before the previous one's tail has finished.

### 3. Effective Boundary Calculation
Define helper logic to calculate "Effective Start" and "Effective End":
- `eff_start = start - (padding_start / 1000)`
- `eff_end = end + (padding_end / 1000)`
- **Rationale**: Decouples the technical timing from the user's immersion timing.

### 4. Controller Updates
- **`tick_autopause`**: Use the `FSM.active_idx` and its `eff_end` to determine pause time.
- **`navigate_sub`**: Modify seeking to target `eff_start`.

## Risks / Trade-offs
- **Overlaps**: In densely packed dialogue (e.g., overlapping speakers), the "sticky" index might cause a slight delay in highlighting the *next* subtitle. However, for language learning, hearing the full tail of the current subtitle is prioritized over early onset of the next.
- **State Management**: Requires careful resetting of `FSM.active_idx` during manual seeks to prevent it from getting stuck on an old line.
