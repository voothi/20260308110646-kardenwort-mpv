## Why

This change formalizes the FSM Architecture Overhaul introduced in Release v1.2.0. The transition to a unified Finite State Machine was driven by the need to harmonize all operating modes (Subtitles, Drum Context, Autopause) into a predictable, collision-free structure that simplifies maintenance and eliminates race conditions found in earlier ad-hoc script implementations.

## What Changes

- Consolidation of individual scripts (`autopause.lua`, `sub_context.lua`, `copy_sub.lua`) into a single, unified core: `scripts/lls_core.lua`.
- Implementation of a global state tracker (`MEDIA_STATE`) derived from the native `track-list` property, covering states: `NO_SUBS`, `SINGLE_SRT`, `SINGLE_ASS`, `DUAL_SRT`, `DUAL_MIXED`, `DUAL_ASS`.
- Introduction of a singular master tick loop (running at 0.05s) to coordinate all runtime processing for Drum Mode and Autopause.
- Preservation of existing keybinding command signatures to ensure compatibility with existing `input.conf` files.

## Capabilities

### New Capabilities
- `fsm-architecture`: A unified state-driven management system that determines operating context based on active subtitle tracks.
- `unified-tick-loop`: A singular, high-frequency coordination loop that replaces multiple independent periodic timers.

### Modified Capabilities
- None (Structural overhaul).

## Impact

- **Code Maintenance**: Drastic reduction in complexity by moving from scattered boolean flags to a centralized state machine.
- **Performance**: Elimination of uncoordinated timer loops in favor of a single master clock.
- **Reliability**: Mathematical mitigation of processing collisions between different features.
