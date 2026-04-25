# Spec: Live Positioning Sync

## Context
Drum Mode ignored live property updates to subtitle positions, snapping instead to static coordinates.

## Requirements
- Bind manual positioning commands (e.g., `cmd_cycle_sec_pos`) to update the `secondary-sub-pos` property.
- Update `tick_drum()` to derive visual Y coordinates from `mp.get_property_number("secondary-sub-pos")`.
- Ensure that visual updates in Drum Mode are reactive to property changes.

## Verification
- Change the subtitle position while in Drum Mode and verify that the text moves immediately.
- Confirm that the position persists when toggling Drum Mode off and back on.
