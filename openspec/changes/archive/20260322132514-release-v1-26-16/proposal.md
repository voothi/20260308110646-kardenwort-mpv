# Proposal: Smart Font Scaling Integration (v1.26.16)

## Problem
Subtitle font sizes in mpv are relative to the window height. When resizing a window, fonts can become too small to read or too large for the screen. The experimental `fixed_font.lua` script addressed this but lived outside the core engine, creating maintenance overhead and configuration fragmentation. Additionally, "strict" scaling caused aggressive word-wrapping on small windows.

## Proposed Change
Integrate the font scaling logic directly into `lls_core.lua`, implement a "Softer Scaling" formula to balance readability and layout, and expose control via centralized `script-opts`.

## Objectives
- Consolidate all subtitle logic into `lls_core.lua` for a single source of truth.
- Implement the `comp_scale` formula to allow weighted font size compensation.
- Enable users to tune scaling strength via `mpv.conf`.
- Ensure real-time updates by observing window dimensions and track changes.
- Deprecate and remove the standalone `fixed_font.lua` script.

## Key Features
- **Core Scaling Integration**: Native handling of font size adjustments within the main script.
- **Softer Scaling Formula**: `comp_scale = 1.0 + (perfect_comp - 1.0) * Options.font_scale_strength`.
- **Configurable Scaling Strength**: New `font_scale_strength` option in `script-opts`.
- **Real-Time Property Observation**: Automated updates on `osd-dimensions` and `track-list` changes.
