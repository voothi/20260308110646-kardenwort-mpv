# Specification: libass Layout and Alignment

## Positioning Strategy
To maintain absolute visual parity, all LLS overlays use a unified `\an` (Alignment) and `\pos` strategy.

### Alignment Constants
- **Center-Aligned Screens** (Drum Mode, SRT, Drum Window):
    - Use `{\an8}` (Top-Center) or `{\an2}` (Bottom-Center).
    - Positioned at `\pos(960, Y)` on a 1920x1080 canvas.
- **Side-Aligned Overlays** (Tooltips):
    - Use `{\an6}` (Right-Center) or `{\an4}` (Left-Center).
    - Positioned at `\pos(X, Y)` where Y is the vertical midpoint of the target logical line.

### Line Wrapping
- **Wrap Style `\q2`**: Must be used for all multi-line blocks to ensure that the vertical height of a block is always a predictable multiple of the logical line height, preventing ASS-internal layout shifting.
