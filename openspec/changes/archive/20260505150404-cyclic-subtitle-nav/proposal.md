# Proposal: Cyclic Subtitle Navigation and First-Sub Bug Fix

## Context
The Kardenwort-mpv immersion suite currently uses a clamped navigation system for subtitles, where seeking previous at the first subtitle or next at the last subtitle does not wrap around. Additionally, a bug has been reported in "PHRASE" immersion mode where playing the first subtitle again (or seeking back to it) causes an unintended switch to the last subtitle.

## Objective
Implement cyclic (wrap-around) navigation for the `a` and `d` keys, resolve state-machine inconsistencies at track boundaries, and ensure robust synchronization when using the native `mpv` OSC timeline.

## What Changes
- `cmd_dw_seek_delta` updated to use modulo-based cyclic indexing.
- Implemented `math.max(0, s)` guards to prevent invalid seeking at the track start.
- Hardened `master_tick` jump detection to trigger `MANUAL_NAV_COOLDOWN` for native OSC seeks.
- Optimized "Jerk Back" logic to prevent unintended jumps during extreme wrap-around transitions.
- Navigation feedback (OSD) updated to reflect cyclic transitions ("Wrapped to START/END").

## Capabilities

### New Capabilities
- `cyclic-navigation`: Enables wrap-around behavior for subtitle-based seeking.

### Modified Capabilities
- `immersion-engine`: Hardening of the Phrases mode logic to ensure stability at boundary conditions.

## Impact
- `lls_core.lua`: Modification of navigation and tick logic.
- `input.conf`: No changes needed as bindings are already in place.
