## Why

Currently, styling settings for different subtitle modes (SRT, Drum, Drum Window, Tooltips) are fragmented across various configuration parameters with inconsistent naming conventions. This fragmentation prevents users from achieving a cohesive visual experience and makes it tedious to synchronize basic aesthetic properties like fonts and transparency across different interface elements.

## What Changes

- **Unified Interface**: Standardize the configuration schema for styling across all four modes: SRT, Drum (c), Drum Window (w), and Tooltip.
- **Font Customization**: Add the ability to specify a custom font name (`font_name`) and toggle font strength/boldness for each mode.
- **Transparency Control**: Unify the "frame" or window transparency settings across all modes that utilize a background box.
- **Sizing Consistency**: Synchronize how font sizes are handled to ensure a premium, predictable visual hierarchy.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `subtitle-rendering`: Add unified font name and strength/boldness requirements for standard SRT and Drum rendering.
- `drum-window`: Implement explicit font selection and unify background transparency requirements.
- `drum-window-tooltip`: Add font name and boldness controls to ensure stylistic parity with the parent window.

## Impact

This change will affect the core rendering logic in Lua scripts responsible for SRT, Drum, and Drum Window displays. It will modify `mpv.conf` to include new styled parameters and require updates to the configuration parsing logic to handle the unified styling interface.
