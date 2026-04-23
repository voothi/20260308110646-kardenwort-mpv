## Context

The Drum Window uses a parchment/beige background theme (`A9C5D4`). The initial dark navy color was too close in luminance to the background when viewed under certain lighting conditions or monitor calibrations, making it difficult to "snap" the eyes to the current line.

## Goals / Non-Goals

**Goals:**
- Increase the luminance and contrast of the active line indicator.
- Maintain a consistent visual language within the reading mode.

## Decisions

- **Color Selection**: `D02020` (Bright Blue in BGR) was selected for its high contrast against the desaturated beige background. It provides a clear "active" state without the visual vibration of pure bright primary colors.
- **Scoping**: This change is limited to the `dw_active_color` variable. All other OSD elements (like highlights and text) are preserved to maintain the "dictionary-like" aesthetic of the reading mode.

## Risks / Trade-offs

- **Risk**: Color clashing with specific user-defined OSD styles.
- **Mitigation**: The new color remains in the blue family, which is the established "interactive" color for this suite.
