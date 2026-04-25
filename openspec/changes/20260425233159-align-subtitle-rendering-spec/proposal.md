## Why

The system recently encountered a critical regression (`20260425224611`) where ASS subtitles failed to display correctly. This was caused by the "Global Suppression" logic introduced during the move to OSD-based rendering for SRT subtitles. Because the specification mandated hiding all native subtitles when any OSD mode was active, ASS tracks—which contain complex styling that our OSD layer cannot replicate—were being suppressed, resulting in a total loss of subtitles for those tracks. 

This change formally documents the fix for this regression and aligns the specifications with the new track-aware suppression architecture.

## What Changes

- **Bug Fix**: Refactored `master_tick` and `tick_drum` in `lls_core.lua` to calculate visibility on a per-track basis.
- **Track-Aware Suppression**: Native visibility is now only suppressed for tracks that are actively being handled by the OSD layer (typically SRT tracks), while ASS tracks are permitted to render natively.
- **Spec Alignment**: Updated `openspec/specs/subtitle-rendering/spec.md` to transition from "Global Suppression" to "Track-Aware Suppression".

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `subtitle-rendering`: Transitioning from global to track-aware native visibility suppression to support concurrent Native-ASS and OSD-SRT rendering and fix regression 20260425224611.

## Impact

- **Regression Resolution**: Restores full functionality and styling for ASS/SSA subtitle tracks.
- **Specification Integrity**: Restores compliance for the current `lls_core.lua` implementation.
- **User Experience**: Formally protects ASS subtitle styling during multi-track consumption.
