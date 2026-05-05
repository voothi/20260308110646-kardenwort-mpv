# Proposal: Cyclic Subtitle Navigation and First-Sub Bug Fix

## Context
The Kardenwort-mpv immersion suite currently uses a clamped navigation system for subtitles, where seeking previous at the first subtitle or next at the last subtitle does not wrap around. Additionally, a bug has been reported in "PHRASE" immersion mode where playing the first subtitle again (or seeking back to it) causes an unintended switch to the last subtitle.

## Objective
Implement cyclic (wrap-around) navigation for the `a` and `d` keys and resolve the state-machine inconsistency that causes the first subtitle to jump to the end of the track.

## What Changes
- `cmd_dw_seek_delta` will be updated to support cyclic indexing.
- The `master_tick` or `get_center_index` logic will be hardened to prevent "magnetic snapping" or incorrect index calculations at track boundaries.
- Navigation feedback (OSD) will be updated to reflect cyclic transitions.

## Capabilities

### New Capabilities
- `cyclic-navigation`: Enables wrap-around behavior for subtitle-based seeking.

### Modified Capabilities
- `immersion-engine`: Hardening of the Phrases mode logic to ensure stability at boundary conditions.

## Impact
- `lls_core.lua`: Modification of navigation and tick logic.
- `input.conf`: No changes needed as bindings are already in place.
