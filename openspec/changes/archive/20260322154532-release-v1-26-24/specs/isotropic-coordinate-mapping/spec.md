# Spec: Isotropic Coordinate Mapping

## Context
Horizontal hit-test accuracy drifted because it was incorrectly linked to window width.

## Requirements
- Derive the horizontal scaling factor from window height: `scale_isotropic = oh / 1080`.
- Apply this factor to both X and Y coordinate translations.
- Ensure the math correctly handles the 1920x1080 virtual OSD resolution.

## Verification
- Resize the window to a narrow width (e.g., half screen).
- Verify that clicking a word at the edge of a line correctly highlights that word.
