# Design: Fix Startup Navigation Latency

## Context
The script uses a "lazy loading" strategy for subtitle memory (`Tracks.pri.subs`) to keep initialization fast. However, since subtitle navigation keys (`a`/`d`) now depend on this internal table globally, the lazy strategy creates a bug where keys seem broken until a mode toggle "boots" the memory.

## Goals
- Ensure `Tracks.pri.subs` and `Tracks.sec.subs` are populated as soon as a track is identified.
- Support immediate navigation in Normal Mode.

## Decisions

### 1. Centralized Eager Loading
We will consolidate the "boot memory" logic into `update_media_state`.
- **Location**: Place it after the `FSM.MEDIA_STATE` determination, but before ANY mode-specific logic.
- **Implementation**:
  ```lua
  if Tracks.pri.path and #Tracks.pri.subs == 0 then
      Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
  end
  ```

### 2. Remove redundant loading from toggles
We will remove the explicit `load_sub` calls from `cmd_toggle_drum_window` and the Drum-specific block in `update_media_state`.
- **Rationale**: Since it will now be handled globally in `update_media_state`, keeping it in toggles is redundant and could lead to race conditions or duplicate parsing.

## Risks
- **IO Latency**: Extremely large subtitle files might cause a slight hang in the first few property updates at startup. Given the size of standard subtitle files, this is considered acceptable for the UX gain.
