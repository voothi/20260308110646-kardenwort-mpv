## Context

The Drum Window (Mode W) implements a complex tri-palette highlighting system:
- **Orange**: Contiguous database matches.
- **Purple**: Split (non-contiguous) database matches.
- **Brick**: Intersections (Contiguous + Split).

Currently, the third-depth (highest intensity) levels of the Orange and Brick palettes are too similar, causing words in heavy intersections to look indistinguishable from standard contiguous phrases. Furthermore, the manual selection stage used a "Pale Yellow" for all multi-word selections, providing no visual indication that a Ctrl+LMB selection would results in a "Cool" (Purple) split match.

## Goals / Non-Goals

**Goals:**
- Improve visual hierarchy by ensuring Level 3 highlights remain distinct.
- Implement **Chromatic Selection Pairing**: linking selection colors to their resulting match palettes (Yellow $\rightarrow$ Orange, Violet $\rightarrow$ Purple).
- Correct misleading documentation in `mpv.conf`.
- Ensure all hardcoded fallbacks and configuration defaults are synchronized.

**Non-Goals:**
- Changing the intensity calculation logic (O+S-1).
- Modifying the Purple (split) palette itself, as it already provides high contrast.

## Decisions

### Chromatic "Warm vs Cool" Pairing
The selection theme for manual split matches (Ctrl+LMB) will be changed from **Pale Yellow** to **Vivid Violet** (#FF00FF). 
- **Rationale**: This creates a logical UI split. Warm colors (Yellow/Orange) signify contiguous, "simple" matches. Cool colors (Violet/Purple) signify split, "complex" matches. 
- **Gamma Matching**: Magenta (#FF00FF) is the chromatic partner to Yellow (#00FFFF). They share similar perceived intensity and saturation, ensuring the selection cursor feels equally "active" in both modes.

### Level 3 Hex Calibration
We are shifting the High-Intensity (Level 3) colors to expand the RGB distance:
- **Orange D3**: Updated from `003A70` (R:112, G:58) to **`003C88`** (R:136, G:60). This increases vibrancy and "warmth".
- **Brick D3**: Updated from `202078` (R:120, G:32, B:32) to **`151578`** (R:120, G:21, B:21). This purifies the red, removing green/blue muddying.
- **Rationale**: The new delta ($16R, 39G, 21B$) is significantly larger than the previous delta ($8R, 26G, 32B$) and shifts the intersection toward a deeper "Brick" while keeping Orange distinctively "Gold".

### Synchronization of Fault-Tolerant Fallbacks
The rendering loops in `lls_core.lua` use hardcoded string literals as late-stage fallbacks if `Options` are missing. 
- **Decision**: These literals MUST be updated alongside the `Options` defaults and the `mpv.conf` entries to prevent "visual regressions" if a user resets their configuration.

## Risks / Trade-offs

- **[Risk] Saturated Magenta is loud** → [Mitigation] Manual selections are transient; the high saturation helps users confirm they are in the "Split Selection" mode (Ctrl held) versus a standard drag.
- **[Trade-off] Brick Purity** → Making the brick color "purer red" increases contrast but moves it away from the purple/orange "muddy" mix look. This is acceptable for the sake of legibility.
