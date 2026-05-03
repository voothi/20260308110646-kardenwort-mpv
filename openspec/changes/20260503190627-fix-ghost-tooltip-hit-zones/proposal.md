## Why

The current implementation of the Translation Tooltip (activated by 'e' or 'Shift+E' globally) suffers from "Interaction Leakage." When the tooltip is dismissed or suppressed (e.g., during text selection dragging), the script clears the visual OSD but fails to clear the underlying logical hit-zones. 

Because the tooltip hit-test is checked before the main Drum Window hit-test, and because tooltips can be very wide (up to 1400px), these "ghost" hit-zones frequently overlap with the Drum Window's text area. This causes mouse clicks and hovers in the Drum Window to be intercepted by non-existent tooltip lines, leading to misaligned highlights, failed selections, and a perception of lost calibration accuracy.

## What Changes

- **Hit-Zone Lifecycle Management**: The `FSM.DW_TOOLTIP_HIT_ZONES` will be explicitly cleared whenever the tooltip OSD is dismissed or suppressed.
- **Hit-Test Guarding**: The `dw_tooltip_hit_test` function will be updated to return early if the tooltip is not logically active (`FSM.DW_TOOLTIP_LINE == -1`), providing a secondary layer of protection against stale metadata.
- **Improved Interaction Priority**: Ensures that the Drum Window remains fully interactive unless a tooltip is actively being displayed and hovered.

## Capabilities

### New Capabilities
- `tooltip-hit-zone-lifecycle`: Precise management of interactive metadata for tooltips to prevent interaction bleed-through.

### Modified Capabilities
- `osd-hit-zone-sync`: Update the OSD hit-zone synchronization engine to handle multi-layer interaction priorities correctly.

## Impact

- `scripts/lls_core.lua`: Significant hardening of the `dw_tooltip_mouse_update` logic.
- User Experience: Resolved "dead zones" and misalignments in the Drum Window while the tooltip is enabled.
