## Context

Prior to this overhaul, the suite consisted of multiple independent scripts with their own timing loops and internal flags. This architecture led to occasional race conditions and "collisions" in visualization and pause logic.

## Goals / Non-Goals

**Goals:**
- Centralize all operating logic into a single state machine.
- Synchronize all processing to a single clock.
- Harmonize behavior across different combinations of SRT and ASS subtitles.

## Decisions

- **State Consolidation**: Feature logic from `autopause.lua`, `sub_context.lua`, and `copy_sub.lua` is merged into `scripts/lls_core.lua`.
- **Media State Tracker**: The operating mode is determined structurally by parsing the native `track-list`. This ensures that features like Drum Mode can be safely auto-disabled if the `MEDIA_STATE` indicates complex ASS tracks that might cause rendering conflicts.
- **Master Tick**: A single periodic timer at 0.05 seconds handles all runtime tracking. This replaces multiple asynchronous timers and ensures that state updates are sequential and predictable.
- **Preserved API**: Internal script-message handlers and command signatures are kept identical to their previous ad-hoc versions to maintain compatibility with the user's `input.conf`.

## Risks / Trade-offs

- **Risk**: A single point of failure in `lls_core.lua`.
- **Mitigation**: The code is simplified by removing redundant logic and flag-checking, making it easier to debug.
- **Risk**: Performance impact of a fast 0.05s tick loop.
- **Mitigation**: The loop logic is kept lean, focusing only on critical state tracking and coordinate calculations.
