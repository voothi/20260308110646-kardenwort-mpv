## Context

The current Drum Window navigation logic suffers from race conditions between key-press events and playback state updates. Previous attempts to fix this added complex, stateful "activation guards" and "repeat locks" which failed to provide 100% reliability and increased code complexity.

## Goals / Non-Goals

**Goals:**
- Implement a deterministic, snapshot-based navigation resolution pattern.
- Eliminate the boundary-jumping lag for all arrow keys.
- Restore the "UP enters middle-word" requirement for active listening.
- Simplify `main.lua` by removing previous failed guard mechanisms.

**Non-Goals:**
- Changing the rendering engine or OSD layout.
- Modifying mouse-based interaction.

## Decisions

### 1. Unified Event Snapshotting
- **Decision**: Introduce a `nav_event_snapshot(evt)` function that captures all required state at the exact moment of invocation.
- **Rationale**: Decouples the navigation logic from the volatile `mp.get_property` calls. If a key is pressed at T=1.0s, the entire handler sees T=1.0s, even if the player has moved to T=1.05s by the end of the script execution.

### 2. Hard-Lock for Initial Activation
- **Decision**: In `cmd_dw_line_move`, the transition from `POINTER_NULL_FOLLOW` to `POINTER_ACTIVE_MANUAL` will be hard-locked to the snapshot's resolved index.
- **Rationale**: Prevents the system from "scanning" for a better line, which was the primary source of the boundary-jump lag. If you press UP, you stay on the line the system resolved at that moment.

### 3. Middle-Entry as a Deterministic Branch
- **Decision**: Implement the middle-entry behavior as a hard code branch inside `cmd_dw_line_move` for the first-activation UP case.
- **Rationale**: Removes ambiguity and ensures the USER's primary requirement is satisfied without relying on complex heuristics.

## Risks / Trade-offs

- [Risk] → Snapshots might be slightly different from OSD state due to rendering lag.
- [Mitigation] → Use `mp.get_property_number("time-pos")` directly in the snapshot rather than cached script variables to ensure the most "current" possible player state.
- [Risk] → Removing previous guards might re-introduce repeat-key drift.
- [Mitigation] → Ensure the snapshot logic properly identifies the `repeat` flag and handles it according to the FSM rules (e.g., ignoring repeat during the initial null-to-active transition).
