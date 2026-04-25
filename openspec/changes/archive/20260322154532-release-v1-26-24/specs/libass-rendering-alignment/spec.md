# Spec: Libass Rendering Alignment

## Context
The hit-test math must mirror how the subtitle renderer (`libass`) actually positions text.

## Requirements
- Respect that `libass` preserves aspect ratio by scaling text based on window height.
- Account for letterboxing/pillarboxing (if any) implicitly via the isotropic scaling logic.
- Ensure the selection grid is pixel-perfect with the visual representation of the text.

## Verification
- Use the Debug OSD to visualize the hit-test bounding boxes.
- Confirm they perfectly overlay the rendered text regardless of window size.
