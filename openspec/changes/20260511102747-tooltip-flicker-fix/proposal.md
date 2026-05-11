# Proposal: Fix Tooltip Flickering in Drum Window

## Problem
The tooltip window in Drum Window (DW) mode exhibits cyclical flickering when holding RMB, especially in specific screen areas. This is likely caused by redundant OSD updates on every master tick (20Hz) even when the content hasn't changed. Additionally, floating-point jitter in line centering could be causing cache misses in the tooltip renderer.

## Rationale
- **Redundant Updates**: `dw_tooltip_mouse_update` calls `dw_tooltip_osd:update()` on every tick while RMB is held, regardless of whether the tooltip content has changed.
- **Cache Instability**: If the main DW layout re-calculates Y-positions with sub-pixel differences (e.g., due to odd total heights), the tooltip cache will miss, leading to re-rendering and slight position shifts.
- **Mechanism**: The "cyclically continuous" flashing described by the user matches the 20Hz master tick rate.

## Evidence
- Flickering capture: `C:\Users\voothi\Videos\Recording 2026-05-11 105230.mp4`
- Detailed analysis: [analysis.md](./analysis.md)

The video demonstrates the continuous flickering of the tooltip OSD when the mouse is held stationary over the word "die" in Fragment2.

## Proposed Changes

### 1. Guard OSD Updates
Modify `dw_tooltip_mouse_update` to only call `update()` if the generated ASS string differs from the current OSD data. This prevents redundant work and potential OSD flickering.

### 2. Stabilize Cache Keys
Ensure that `osd_y` used for tooltips is stable. If it's a calculated line center, round it or ensure the calculation is deterministic.

### 3. Improve `dw_hit_test` Robustness
Ensure that small mouse jitters don't cause word-level oscillation that might invalidate caches (even if the tooltip content for the line is the same, the word highlight might change).

## Verification Plan
- **Automated Test**: Create an acceptance test that holds RMB at a fixed position and verifies that `dw_tooltip_osd:update` is not called excessively.
- **Manual Verification**: Test the specific subtitle fragment `Stunde um die 800 Sendungen` in DW mode to ensure the blinking is resolved.
