## Why

Currently, the selection and highlighting logic across various modes (Drum Window, Drum Mode, Regular SRT) is hardcoded to use a single set of global color settings. This prevents independent calibration of selection brightness for different tracks (Primary vs. Secondary) and different rendering contexts, which is critical when balancing readability across diverse fonts (like Consolas) and high-contrast background modes.

## What Changes

- **Universal Explicit Colors**: Introduce independent `highlight_color` and `ctrl_select_color` script options for every interaction mode and track (Drum Window, Tooltip, Drum Mode Pri/Sec, SRT Mode Pri/Sec).
- **Boldness Synchronization**: Synchronize highlight weight across all modes, ensuring that manual selections (Yellow/Pink) remain regular weight to match the Drum Window, while database matches remain bold.
- **Architectural Parameterization**: Refactor the core `populate_token_meta` and `format_highlighted_word` services to accept dynamic color and boldness palettes.
- **Independent Luminance Tuning**: Enable precise tuning of selection brightness and weight per screen and per mode.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `drum-window-tooltip`: Add requirements for independent selection and multi-word highlight colors.
- `rendering-optimization`: Update the `populate_token_meta` architectural invariant to support parameter-driven colorization across all OSD rendering loops.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (Options, `populate_token_meta`, `draw_drum`, `draw_dw_core`, and `draw_dw_tooltip`).
- **Configuration**: `mpv.conf` will receive a comprehensive suite of new `script-opts` for granular highlight control.
- **User Experience**: Professional-grade aesthetic control over interaction markers across dual-subtitle tracks.
