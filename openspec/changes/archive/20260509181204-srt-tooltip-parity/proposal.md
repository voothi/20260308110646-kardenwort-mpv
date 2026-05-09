## Why

Users who prefer the standard SRT view (without the full Drum Window) currently lack access to the translation tooltip system. This creates a functional gap where users must switch modes just to see a translation or dictionary entry. Enabling tooltips in SRT mode provides a more seamless and consistent experience across all subtitle rendering modes.

## What Changes

- **Modify Tooltip Eligibility**: Expand the tooltip system's activation logic to include SRT mode (custom OSD rendering) in addition to Drum Mode and Drum Window.
- **Unified Interaction**: Ensure that keyboard toggling ('e'), mouse pinning (RMB), and hover modes work identically in SRT mode as they do in Drum Mode.
- **Requirement Update**: Remove the restriction that tooltips are "restricted entirely to the Drum Window mode" from the specifications.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `drum-window-tooltip`: Remove mode-specific restrictions to allow tooltip operation in SRT and Drum Mode OSDs.

## Impact

- `scripts/lls_core.lua`: Update `is_drum_tooltip_mode_eligible` (and likely rename it to `is_osd_tooltip_mode_eligible`) and refine hit-zone logic if necessary to ensure SRT mode compatibility.
- `openspec/specs/drum-window-tooltip/spec.md`: Update requirements to reflect multi-mode support.
