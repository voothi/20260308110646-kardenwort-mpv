## Context

Currently, `drum_osd_hit_test` in `lls_core.lua` performs strict bounding-box checks for mouse coordinates. If the user clicks in the vertical gap between lines in Drum Mode, the interaction fails. This contrasts with Drum Window (`dw_hit_test`), which implements a more permissive "snap-to-nearest" logic for vertical gaps.

## Goals / Non-Goals

**Goals:**
- Implement vertical proximity snapping in `drum_osd_hit_test` to allow interactions in gaps between lines.
- Maintain strict horizontal bounds (no horizontal snapping beyond a small tolerance) to avoid accidental triggers when clicking outside the text block.
- Ensure parity between Drum Mode (OSD) and Drum Window interaction models.

**Non-Goals:**
- Changing how hit zones are populated in `draw_drum`.
- Implementing horizontal proximity snapping.

## Decisions

- **Vertical Snapping Algorithm**: Modify `drum_osd_hit_test` to iterate through all zones, filter by horizontal alignment first, and then find the one with the minimum vertical distance to `osd_y`.
- **Proximity Threshold**: Introduce a vertical snap threshold (e.g., 60 pixels) to prevent snapping to lines from across the screen (e.g., from secondary track at top to primary track at bottom).
- **Priority**: Direct hits (where `dist_y == 0`) will naturally have the highest priority.

## Risks / Trade-offs

- **Overlapping Zones**: If two lines are extremely close or overlapping (unlikely with current rendering), the nearest-center logic might be ambiguous. However, since we check horizontal bounds first and use `min_y_dist`, it should remain stable.
- **Complexity**: Slightly more computation in the hit-test loop, but since `DRUM_HIT_ZONES` typically contains fewer than 20-30 lines, the performance impact is negligible.
