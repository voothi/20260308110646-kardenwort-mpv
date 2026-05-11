## Why

The Drum Window (DW) mode currently has inconsistent OSD feedback for certain global keys and contains "unnecessary noise" in its status label. Unifying these labels and suppressing redundant OSD feedback when DW mode is active improves UI clarity and ensures a consistent "managed" experience.

## What Changes

- **Renamed Status Label**: "Drum Window: Active (Position Locked)" is shortened to "Drum Window: Active" to reduce visual noise.
- **Unified Managed Inscriptions**: Pressing `Shift+x`, `c`, `Shift+c`, and `Shift+f` while in DW mode will now display "Managed by Drum Window", similar to the existing behavior for `x`.
- **Keyboard Override Hardening**: Ensures these specific global shortcuts do not trigger their default actions while DW mode is active.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window`: Update interaction and OSD feedback requirements to include unified "Managed by" inscriptions for specific keys and simplified active status label.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (OSD logic and key handlers).
- **User Experience**: Cleaner status feedback and consistent notification when attempting to use blocked global shortcuts in Drum Window mode.
