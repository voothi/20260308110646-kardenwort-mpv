## Context

The Drum Window (Mode W) implements a complex tri-palette highlighting system:
- **Orange**: Contiguous database matches.
- **Purple**: Split (non-contiguous) database matches.
- **Brick**: Intersections (Contiguous + Split).

Currently, the third-depth (highest intensity) levels of the Orange and Brick palettes are too similar, causing words in heavy intersections to look indistinguishable from standard contiguous phrases. 
Furthermore, the manual selection stage used a **"Pale Yellow"** (#66E0FF) and **"Bright Yellow"** (#00FFFF) for all multi-word selections, providing no visual indication that a selection would results in a "Cool" (Purple) split match or a "Warm" (Orange) contiguous match. This legacy theme also suffered from low distinguishability against gray/white in dimmed environments.

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
The selection theme for manual split matches (Ctrl+LMB) will be changed from **Pale Yellow** to **Neon Pink** (#FF88FF). 
- **Rationale**: This creates a logical UI split. Warm colors (Gold/Orange) signify contiguous matches. Cool colors (Pink/Purple) signify split matches. 
- **Intensity Matching**: Neon Pink (#FF88FF) is calibrated to match the perceptual intensity of Gold (#00CCFF). By adding light Green/White to the violet base, we ensure the "Cool" selection doesn't look too dark or muddy compared to the main highlight.

### Level 3 Hex Calibration
We are shifting the High-Intensity (Level 3) colors to expand the RGB distance and pull selections away from pure White:
- **LMB Focus**: Updated from Yellow (#00FFFF) to **Gold (#00CCFF)** to prevent confusion with white in dimmed environments.
- **Orange D3**: Updated from `003A70` to **`003C88`**.
- **Brick D3**: Updated from `202078` to **`151578`**.
- **Rationale**: The shift ensures that the most intense selections and matches occupy distinct, well-separated areas of the color spectrum even at low luminosity.

### Synchronization of Fault-Tolerant Fallbacks
The rendering loops in `lls_core.lua` use hardcoded string literals as late-stage fallbacks if `Options` are missing. 
- **Decision**: These literals MUST be updated alongside the `Options` defaults and the `mpv.conf` entries to prevent "visual regressions" if a user resets their configuration.

## Risks / Trade-offs

- **[Risk] Saturated Magenta is loud** → [Mitigation] Manual selections are transient; the high saturation helps users confirm they are in the "Split Selection" mode (Ctrl held) versus a standard drag.
- **[Trade-off] Brick Purity** → Making the brick color "purer red" increases contrast but moves it away from the purple/orange "muddy" mix look. This is acceptable for the sake of legibility.
