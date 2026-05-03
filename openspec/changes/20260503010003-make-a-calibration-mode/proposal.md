# Proposal: Calibration Mode (Visual Debug & Self-Adjusting)

## Problem

The Kardenwort-mpv ecosystem relies on a sophisticated OSD interaction engine for word selection and highlighting. This engine depends on several "Magic Multipliers" (e.g., `dw_char_width`, `dw_line_height_mul`, `dw_vsp`) that map monospaced text to pixel-perfect hit-zones. 

Currently, these parameters are calibrated for a specific font (Consolas) and size (34). When users switch fonts or sizes, the hit-zones drift, causing mouse interactions to become misaligned. Correcting this requires a tedious "guess-and-check" cycle involving manual edits to `mpv.conf` and player reloads.

## Objective

Create a dedicated **Calibration Mode** that provides visual feedback of the underlying hit-testing geometry and allows for real-time tuning of the calibration multipliers. This will enable users to achieve pixel-perfect interaction with any font or layout configuration in seconds.

## What Changes

1.  **Calibration Overlay**: A new rendering pass that draws semi-transparent bounding boxes over every word/line in interactive OSD modes (Drum Window, Drum Mode).
2.  **Live Adjustment Interface**: A set of transient keybindings active only during Calibration Mode to increment/decrement multipliers (`char_width`, `line_height`, `vsp`) with immediate visual updates.
3.  **Persistence Engine**: A mechanism to "Save" the calibrated values by appending them to a persistent configuration file (`mpv.conf` or a dedicated `.conf` sidecar).
4.  **Auto-Probing (Optional/Future)**: Support for a simple calibration sequence (e.g., "Click the end of this line") to mathematically derive `char_width`.

## Capabilities

### New Capabilities
- `calibration-mode`: The core logic for toggling the debug overlay and managing the live tuning state.
- `config-persistence`: A utility to safely write/append calibrated parameters to the user's configuration files.

### Modified Capabilities
- `drum-window`: Needs to integrate the calibration overlay rendering pass.
- `drum-mode`: Needs to integrate the calibration overlay rendering pass.

## Impact

- **lls_core.lua**: Significant additions to the rendering and FSM logic to handle the debug overlay.
- **mpv.conf**: New default settings for calibration state and potential append-point for saved values.
- **User Experience**: Drastically reduced friction for custom font setups.
