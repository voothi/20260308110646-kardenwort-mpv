# Spec: X-Axis Re-Anchoring

## Context
Centrally rendered text requires center-relative mouse coordinate math to remain accurate in narrow windows.

## Requirements
- Identify the physical screen center: `ow / 2`.
- Calculate the horizontal offset of the mouse from this center.
- Map this offset to the virtual OSD space relative to the center `960`.
- Formula: `virtual_x = 960 + (mx - ow / 2) / scale_isotropic`.

## Verification
- Snap the window to the left side of the screen.
- Verify that word selection remains accurate.
- Snap the window to the right side and verify accuracy.
