## Why

The Drum Window (`w`) currently uses a large, vectored black rectangle as a global background, which differs significantly from the localized "background-box" aesthetic of the standard Drum Mode (`c`). To achieve visual parity and improve readability, the Drum Window's environment and text parameters (borders, shadows, and background style) MUST be aligned with Drum Mode, transitioning from a global panel to line-based background boxes.

## What Changes

- **Environmental Alignment**: Remove the global vector background rectangle in Drum Window (`draw_dw`).
- **Text Styling**: Remove the `\bord0\shad0` overrides in the Drum Window renderer to allow it to inherit the project's `background-box` OSD style.
- **Font Size Normalization**: Visually normalize the size of `Consolas` in `w` mode to match the perceived scale of the proportional font used in `c` mode (approximately a 10-15% increase in font size).
- **Tooltip Unification**: Synchronize the Tooltip's transparency and text parameters with the Drum Window (`w`) to ensure a unified immersion experience across all HUD components.
- **Visual Parity**: Synchronize border and shadow parameters between `c` and `w` modes, ensuring Anki highlights and text appear "fuller" and consistent across both interfaces.
- **Theme Transition**: Transition Anki highlights from Green shades to the project's signature Orange/Gold palette (`0075D1`, `005DAE`, `003A70`).
- **Search HUD Fix**: Update Search selection from Blue to White for readable contrast on dark backgrounds.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `drum-window`: Modifies the core aesthetic requirement from "global-pane interface" to "localized-box interface" to match Drum Mode and maintain cross-mode visual continuity.

## Impact

- `lls_core.lua`: Refactor `draw_dw` to remove background vectoring and border overrides.
- `mpv.conf`: Alignment of `lls-dw_bg_opacity` values with global OSD background box opacity if necessary, though it will now primarily rely on global OSD style.
