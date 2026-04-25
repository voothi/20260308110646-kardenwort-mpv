## Why

The recent v1.50.0 compliance audit and subsequent fix for ASS subtitles identified a critical mismatch between the `subtitle-rendering` specification and the required user experience. The specification currently mandates "Global Suppression" of all native subtitles whenever an OSD mode (like SRT-OSD) is active. However, this causes ASS subtitles—which cannot be rendered via OSD without losing complex styling—to be hidden entirely. This proposal aligns the documentation with the track-aware suppression logic implemented to resolve this regression.

## What Changes

- **Update Specification**: Modify `openspec/specs/subtitle-rendering/spec.md` to transition from "Global Suppression" to "Track-Aware Suppression".
- **Refine Requirements**: Formally document the exception for ASS/SSA tracks, allowing them to render natively even when OSD modes are active for other tracks.
- **System Synchronization**: Ensure the "Force to False" requirement in `master_tick` is technically constrained to only those tracks being handled by the OSD layer.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `subtitle-rendering`: Transitioning from global to track-aware native visibility suppression to support concurrent Native-ASS and OSD-SRT rendering.

## Impact

- **Specification Integrity**: Restores compliance for the current `lls_core.lua` implementation.
- **User Experience**: Formally protects ASS subtitle styling during multi-track consumption.
- **Future Audits**: Prevents false-positive compliance failures in future system-wide audits.
