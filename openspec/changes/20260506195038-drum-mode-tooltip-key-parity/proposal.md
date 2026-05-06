## Why

Drum Mode (C) currently lacks the reliable tooltip-key workflow that users already depend on in Drum Window (W), especially for the bottom primary-subtitle surface. This creates inconsistent behavior and blocks the intended “mini z-reel window” workflow when users stay in Drum Mode.

## What Changes

- Add a Drum-Mode tooltip interaction path for the main (bottom) subtitle area, driven by the same coordinated key model used in Drum Window.
- Ensure the configured tooltip trigger key(s) execute the correct action in Drum Mode with layout parity (e.g., EN/RU key variants), instead of requiring Drum Window-only state.
- Reuse DW tooltip semantics where applicable (toggle/hold behavior, lifecycle guards, visibility invalidation) while keeping Drum and DW render ownership mutually safe under the FSM.
- Introduce a dedicated “mini z-reel” behavior contract for Drum Mode tooltip usage that intentionally excludes Book Mode migration.
- Preserve existing Book Mode behavior unchanged and out of scope.

## Capabilities

### New Capabilities
- `drum-mini-z-tooltip-mode`: Defines Drum Mode as a mini z-reel interaction surface for tooltip operations on the primary subtitle stream.

### Modified Capabilities
- `fsm-architecture`: Extend mode/overlay mutex and input routing rules so Drum Mode can host tooltip interactions without violating DRUM vs DRUM_WINDOW ownership boundaries.
- `coordinated-input-system`: Extend coordinated `dw_key_*` routing to support Drum-Mode tooltip execution with layout-aware parity and correct key ownership.
- `subtitle-rendering`: Add Drum-Mode tooltip rendering behavior for primary subtitle hit-zones and lifecycle-safe draw/clear conditions.
- `tooltip-hit-zone-lifecycle`: Extend lifecycle and guard clauses to include Drum-Mode tooltip hit-zones, not only Drum Window.

## Impact

- Affected code: `scripts/lls_core.lua` (input binding orchestration, FSM transition guards, hit-zone generation, tooltip draw pipeline).
- Affected runtime behavior: key handling in Drum Mode, tooltip overlay ownership, and render invalidation paths.
- Compatibility: no Book Mode changes; existing DW behavior must remain backward-compatible.
- Verification: requires scenario testing across Regular SRT, Drum Mode, Drum Window, and ASS-gated contexts to avoid state-transition regressions.
