## Context

The 50ms `master_tick` loop introduced in v1.2.0 was re-reading native mpv properties (`secondary-sub-pos`) faster than user commands could settle, leading to state-reversion bugs. Additionally, memory management for track-switching needed to be more aggressive to prevent old track data from lingering.

## Goals / Non-Goals

**Goals:**
- Harmonize user command persistence with high-frequency state polling.
- Ensure memory arrays are strictly synchronized with the current track list.
- Prevent invalid feature execution (e.g., repositioning ASS tracks).

## Decisions

- **State Buffering**: `FSM.native_sec_sub_pos` is introduced to store the user's *intended* state. The FSM now treats this as the source of truth, restoring it to mpv during shutdown or Drum OFF transitions.
- **Aggressive Flushing**: `update_media_state` is updated to compare current track paths with the previous state. Any change or removal of a track triggers an immediate `Tracks.subs` array flush.
- **Feature Guarding**: A centralized guard layer in `lls_core.lua` checks `MEDIA_STATE` and track types before allowing key handlers for `y`, `Ctrl+Z`, and `Ctrl+X` to execute.

## Risks / Trade-offs

- **Risk**: Over-aggressive guards blocking valid use cases.
- **Mitigation**: Guards are specifically mapped to mathematical limitations (e.g., ASS tracks handle their own positioning, so `y` is logically redundant).
