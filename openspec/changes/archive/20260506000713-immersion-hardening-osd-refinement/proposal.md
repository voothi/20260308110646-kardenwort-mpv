## Why

The Kardenwort-mpv immersion engine requires hardening to ensure that active study sessions are not interrupted by accidental inputs or redundant UI feedback. The previous OSD system was inconsistent, displaying either too much technical detail (noise) or no descriptive context at all. Furthermore, navigation interactions like the `Esc` key were causing unintended state transitions (cyclic switching), which disrupted the user's flow.

## What Changes

- **Immersion Key Hardening**: Subtitle positioning keys (`r`, `t`, `R`, `T` and Cyrillic equivalents) are now managed via `forced` key bindings. They are silently blocked when the Drum Window or Drum Mode is active to prevent accidental visual shifts.
- **Descriptive Minimalism (OSD)**: All system toggles and status messages have been refactored to show descriptive prefixes (e.g., `Drum Mode: ON`, `Subtitle Visibility: OFF`) without the technical noise previously present.
- **Context-Aware Feedback**: Copying actions now distinguish between regular and window-based contexts (e.g., `DW Copied A: ...`).
- **Interaction Refinement**: The `Esc` logic has been refactored into a staged reset process that clears selections, ranges, and pointers sequentially without closing the Drum Window, preventing cyclic mode toggling.
- **UI Shortening**: Long OSD prefixes (e.g., `Secondary Subtitles:`) have been shortened (e.g., `Secondary Sub:`) to reduce visual clutter.

## Capabilities

### New Capabilities
- `immersion-hardening`: Priority-based input blocking and state protection during active immersion sessions.
- `osd-descriptive-minimalism`: A standardized feedback system that provides clear labeling without technical noise.

### Modified Capabilities
- `drum-mode`: Requirements updated to include input blocking for positioning keys.
- `drum-window`: Selection reset logic on `Esc` now requires maintaining the window state.

## Impact

- `lls_core.lua`: Centralized OSD logic, refactored `cmd_dw_esc`, and updated key registration.
- `mpv.conf`: New configuration options for managed positioning keys.
