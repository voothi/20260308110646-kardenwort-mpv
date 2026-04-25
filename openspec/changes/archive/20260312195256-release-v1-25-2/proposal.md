## Why

This change formalizes the Drum Window Visibility Enhancement introduced in Release v1.25.2. As the Drum Window (Static Reading Mode) is used for intensive text analysis, it is critical that the "active" line (corresponding to the current playback position) is immediately identifiable. This update resolves a legibility issue where the previous dark navy indicator lacked sufficient contrast against the parchment-colored background.

## What Changes

- Adjustment of the **Active Line Color**: The `dw_active_color` in `lls_core.lua` has been updated from a dark Navy (`800000`) to a high-contrast Bright Blue (`D02020`).
- Maintenance of **Visual Hierarchy**: This change is scoped strictly to the Drum Window OSD; the standard Drum Mode overlay color remains unchanged to preserve its own contrast requirements against video content.

## Capabilities

### New Capabilities
- `dw-visual-optimization`: A set of aesthetic and ergonomic refinements focused on improving the readability and user focus within the static reading environment.

### Modified Capabilities
- None (Incremental aesthetic refinement).

## Impact

- **Improved Focus**: Faster visual identification of the current sentence during immersion sessions.
- **Reduced Eye Strain**: Better contrast ratios lead to a more comfortable long-term reading experience.
- **Aesthetic Refinement**: A more modern, "vibrant" blue that aligns with professional UI standards.
