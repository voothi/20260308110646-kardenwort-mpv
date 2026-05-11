# Spec: Libass Rendering Alignment

## Context
The hit-test math must mirror how the subtitle renderer (`libass`) actually positions text.

## Requirements
- Respect that `libass` preserves aspect ratio by scaling text based on window height.
- Account for letterboxing/pillarboxing (if any) implicitly via the isotropic scaling logic.
- Ensure the selection grid is pixel-perfect with the visual representation of the text.

### Positioning Strategy
To maintain absolute visual parity, all Kardenwort overlays use a unified `\an` (Alignment) and `\pos` strategy.

1.  **Alignment Constants**:
    - **Center-Aligned Screens** (Drum Mode, SRT, Drum Window): Use `{\an8}` (Top-Center) or `{\an2}` (Bottom-Center), positioned at `\pos(960, Y)` on a 1920x1080 canvas.
    - **Side-Aligned Overlays** (Tooltips): Use `{\an6}` (Right-Center) or `{\an4}` (Left-Center), positioned at `\pos(X, Y)` where Y is the vertical midpoint of the target logical line.
2.  **Line Wrapping**: Wrap Style `\q2` must be used for all multi-line blocks to ensure that the vertical height of a block is always a predictable multiple of the logical line height.

## Verification
- Use the Debug OSD to visualize the hit-test bounding boxes.
- Confirm they perfectly overlay the rendered text regardless of window size.

