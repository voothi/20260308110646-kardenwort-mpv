# Proposal: Isotropic Mouse Hit-Testing (v1.26.24)

## Problem
Text selection accuracy in the Drum Window failed when the mpv window was resized or snapped to non-16:9 aspect ratios. The previous hit-test logic assumed that text stretched horizontally to fit the window width, while `libass` actually renders text isotropically (preserving its aspect ratio based on height). This caused massive horizontal drift in selection.

## Proposed Change
Rewrite the coordinate mapping logic in `dw_get_mouse_osd` to use isotropic scaling derived from window height, and re-anchor the X-axis calculation to the physical center of the screen.

## Objectives
- Fix hit-test drift in non-standard aspect ratios and snapped windows.
- Align the hit-test mathematical model with the actual `libass` rendering behavior.
- Ensure pixel-perfect word selection regardless of window dimensions.

## Key Features
- **Isotropic Coordinate Mapping**: X-axis scaling is now linked to window height (`oh / 1080`) instead of width.
- **Physical Center Anchoring**: Mathematical anchor shifted to `ow / 2` to mirror the centered text rendering.
- **Aspect-Ratio Resilience**: Guaranteed selection accuracy across full-screen, split-screen, and custom footprints.
