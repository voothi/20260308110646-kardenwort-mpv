## Why

During high-speed "Autopause OFF" playback in MOVIE mode, the Drum Window pointer activation (UP/DOWN/LEFT/RIGHT) exhibits a boundary lag, often jumping to the previous subtitle when triggered within the first ~200ms of a new subtitle. This is caused by a race condition between engine tick latency and event resolution. This change aims to eliminate this lag with surgical precision, solve the technical debt from previous failed attempts, and ensure deterministic, middle-of-sub entry for the yellow pointer.

## What Changes

- **Surgical Logic Overhaul**: Replace the multi-layered "activation guards" and "repeat locks" with a deterministic state snapshot at the moment of key-down.
- **Hard-Locked Current Line Activation**: Ensure the first null-to-active transition is strictly bound to the active playback index at event-time, preventing "adjacent drift" to neighboring lines.
- **Middle-Entry Priority**: Re-establish the "UP enters from middle" requirement as a primary deterministic rule for live playback.
- **Tech Debt Removal**: Purge the redundant `dw_nav_activation_repeat_is_locked` and `dw_get_live_playback_index_for_activation` hacks in favor of a unified resolution engine.

## Capabilities

### New Capabilities
- `dw-pointer-event-snapshots`: Defines the requirements for capturing deterministic playback state at the moment of a navigation key-event.

### Modified Capabilities
- `drum-window-navigation`: Update activation rules to enforce current-line-only entry and middle-word priority for UP.
- `dm-dw-state-traceability`: Align traceability requirements with the new snapshot-based FSM.

## Impact

- `main.lua`: Significant cleanup of navigation handlers (`cmd_dw_line_move`, `cmd_dw_word_move`).
- `tests/acceptance/`: Update edge-case tests to verify boundary precision.
