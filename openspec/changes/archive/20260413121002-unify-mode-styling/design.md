## Context

The Kardenwort-mpv configuration manages multiple subtitle rendering layers:
1. **Regular SRT**: Standard mpv subtitle rendering.
2. **Drum Mode (c)**: A custom OSD-based rendering mode for immersive consumption.
3. **Drum Window (w)**: A centered, list-based display for detailed analysis.
4. **Tooltip Mode**: Secondary subtitles displayed on demand.

Currently, styling parameters like font selection and weight are inconsistently available across these modes. Users cannot easily synchronize their typography, leading to a fragmented visual experience.

## Goals / Non-Goals

**Goals:**
- Provide a unified set of configuration parameters for all four rendering modes.
- Add explicit support for `font_name` and `font_bold` customization in all modes.
- Synchronize background transparency (`bg_opacity`) and sizing controls.
- Maintain the "premium" aesthetic by ensuring crisp, consistent typography.

**Non-Goals:**
- Changing the underlying rendering technology (ASS/OSD).
- Introducing complex themes or skinning support beyond basic styling parameters.

## Decisions

### 1. Standardized Parameter Schema
We will adopt a consistent naming convention for script options in `mpv.conf`:
- `lls-<mode>-font_name`: Target font family.
- `lls-<mode>-font_size`: Base size for the mode.
- `lls-<mode>-font_bold`: Boolean toggle for font weight.
- `lls-<mode>-bg_opacity`: Alpha value for background boxes (where applicable).

Modes: `srt`, `drum`, `dw`, `tooltip`.

### 2. ASS Tag Injection Strategy
The rendering logic for each mode (primarily within the Lua scripts) will be updated to calculate and inject the corresponding ASS override tags:
- `{\fnFontName}` for font selection.
- `{\b1}` or `{\b0}` for weight.
- `{\alpha&HXX&}` or `\1a`, `\4a` for opacity.

### 3. Font Selection Fallback
To prevent broken rendering if a user specifies an invalid font, the system will fallback to the global `osd-font` or a safe fallback like `Sans` if the specified font is not found on the system.

## Risks / Trade-offs

- **[Risk] Configuration Bloat** → **Mitigation**: Use sensible defaults so users only need to configure what they want to change.
- **[Risk] Visual Collision** → **Mitigation**: Ensure that font size changes in one mode (e.g., Tooltip) don't negatively impact the layout or overlap with the parent mode (e.g., Drum Window).
- **[Trade-off] Multi-mode Complexity** → We accept higher complexity in the configuration parsing logic to provide the user with high-precision control over their reading environment.
