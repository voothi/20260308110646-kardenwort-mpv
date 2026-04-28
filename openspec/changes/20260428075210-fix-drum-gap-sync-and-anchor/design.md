## Context

The `drum_upper_gap_adj` parameter is currently "invisible" because it only affects logical hit-zones and not the visual OSD. Furthermore, in bottom-anchored layouts (the most common user setup), the center line remains stationary regardless of the adjustment, making it impossible to calibrate the primary reading line against vertical drift.

## Goals / Non-Goals

**Goals:**
- Harmonize visual OSD rendering with hit-zone math using `\vsp`.
- Enable calibration of the active center line relative to the layout anchor.
- Ensure 100% click accuracy across all context lines in Drum Mode.

**Non-Goals:**
- Changing the behavior of `drum_double_gap=yes` (where drift is less problematic).
- Implementing multi-font height detection (we stick to manual calibration).

## Decisions

1. **Visual Parity via `\vsp`**:
   The `get_separator` function in `lls_core.lua` will be updated to include an optional `adj` parameter. When `drum_double_gap` is disabled, the separator will generate `{\vsp(adj)}\N{\vsp0}`. This forces the ASS engine to apply the pixel offset directly to the newline, mirroring the `cur_y` logic used for hit-zones.

2. **Anchor-Aware Gap Distribution**:
   To fix the "Center Line Stasis", the logic for where `adj` is applied will be refactored:
   - **Old**: Apply only if `abs_idx < center_idx`.
   - **New**: Apply to all gaps between the **Anchor Point** and the line being rendered. 
   - If `is_top` is false (Bottom Anchor), `adj` will apply to gaps **below** the center line to shift the center and upper lines relative to the bottom.
   - This ensures the user can "push" or "pull" the center line into alignment with their mouse.

3. **Unified Height tracking**:
   A single helper function or shared logic block will calculate the `gap + adj` for both the hit-zone loop and the OSD string builder to prevent future divergence.

## Risks / Trade-offs

- **ASS Tag Overhead**: Adding `\vsp` to every line separator slightly increases the OSD string size, but this is negligible for the typical 5-7 lines in Drum Mode.
- **Complexity**: Differentiating between Top and Bottom anchor logic adds conditional branches to the renderer.
