## Why

The Drum Window highlighting engine suffered from visual ambiguity at high intensity levels, where "Orange" (contiguous) and "Brick" (intersection) matches became nearly indistinguishable. Additionally, the selection cursor theme lacked chromatic consistency with the resulting database matches, using a "Pale Yellow" for terms that eventually turned Purple.

## What Changes

- **Color Contrast Optimization**: Adjusted the third-depth (high intensity) hex values for the Orange and Brick palettes to ensure distinct separation at dark shades.
- **Chromatic Selection Pairing**: Replaced the "Pale Yellow" split-selection color with a **Vivid Violet** theme. This establishes a consistent "Warm Path" (Yellow selection → Orange match) and "Cool Path" (Violet selection → Purple match).
- **Configuration Synchronization**: Aligned the default internal script settings in `lls_core.lua` with the user-facing overrides in `mpv.conf`.
- **Documentation Fix**: Corrected misleading comments in `mpv.conf` that incorrectly described the orange/gold palette as "green."

## Historical Context

This change represents a deliberate transition from the legacy "Yellow-Centric" selection theme to a modern "Chromatically Paired" theme:
- **Legacy "Bright Yellow"** (#00FFFF) $\rightarrow$ **New "Gold"** (#00CCFF)
- **Legacy "Pale Yellow"** (#66E0FF) $\rightarrow$ **New "Neon Pink"** (#FF88FF) (via brief "Vivid Violet" #FF00FF phase)

The transition aims to improve distinguishability from white/gray and provide clear visual feedback for the Warm/Cool match paths.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `window-highlighting-spec`: Updating requirements for palette distinction and selection chromatic pairing.
- `anki-highlighting`: Formalizing the visual transition from split-selection to purple-matched state.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (default options and renderer fallbacks), `mpv.conf` (user overrides).
- **Visuals**: Primary impact on the Drum Window (Mode W) highlighting and mouse interaction.
