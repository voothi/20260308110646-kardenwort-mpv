## Why

Currently, the Translation Tooltip selection and highlighting logic is hardcoded to use the Drum Window's color settings (`dw_highlight_color` and `dw_ctrl_select_color`). This creates an architectural inconsistency and prevents independent calibration of selection brightness, which is especially noticeable when using the high-contrast `background-box` mode with the thicker `Consolas` font.

## What Changes

- **Explicit Tooltip Colors**: Introduce `tooltip_highlight_color` and `tooltip_ctrl_select_color` script options to decouple tooltip selection aesthetics from the main Drum Window.
- **Color Parameterization**: Refactor the core `populate_token_meta` service to accept color parameters instead of relying on hardcoded global options.
- **Independent Calibration**: Allow users to "cool down" or independenty tune the selection brightness in the tooltip mode to ensure optimal readability across different display environments.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `drum-window-tooltip`: Add requirements for independent selection and multi-word highlight colors.
- `rendering-optimization`: Update the `populate_token_meta` architectural invariant to support parameter-driven colorization for O(1) rendering efficiency.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (Options, `populate_token_meta`, and rendering loops).
- **Configuration**: `mpv.conf` will receive new `script-opts` for tooltip highlights.
- **User Experience**: Improved aesthetic control and visual consistency across primary and secondary interactivity modes.
