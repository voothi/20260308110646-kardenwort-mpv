## Why

Currently, visual parameters like background transparency, font weights, and border sizing are inconsistently named and controlled across the platform's four primary subtitle modes (Regular SRT, Drum Mode `c`, Drum Window `w`, and Tooltips). This inconsistency creates "visual friction" for the user and makes precise aesthetic calibration (e.g., matching the background box opacity across all HUDs) needlessly complex.

## What Changes

- **Standardized Schema**: Refactor all styling options in `Options` and `mpv.conf` to follow a unified naming convention: `[mode]_[parameter]` (e.g., `drum_bg_opacity`, `dw_bg_opacity`, `tooltip_bg_opacity`).
- **Explicit HUD Control**: Update the rendering engines for Drum Mode (`c`) and Drum Window (`w`) to explicitly inject secondary/background alpha (`\4a`) and border/shadow tags based on script options, ensuring they are independent of global OSD defaults when configured.
- **Parameter Parity**: Ensure every mode supports the full suite of "Pro" parameters: `font_name`, `font_size`, `bg_opacity`, `text_color`, `bold`, `border_size`, and `shadow_offset`.
- **SRT Context Integration**: Clarify and document the connection between the script's visual parameters and MPV's native `sub-*` / `osd-*` settings for standard SRT playback.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `drum-rendering-persistence`: Standardize styling requirements for Drum Mode.
- `drum-window`: Standardize styling requirements for Drum Window.
- `drum-window-tooltip`: Standardize styling requirements for Tooltips.

## Impact

- `scripts/lls_core.lua`: Refactor of the `Options` table and the `draw_drum`, `draw_dw`, and `draw_dw_tooltip` rendering functions.
- `mpv.conf`: Reorganization of script-opts to reflect the unified styling schema.
