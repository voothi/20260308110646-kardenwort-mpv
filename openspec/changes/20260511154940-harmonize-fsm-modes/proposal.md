## Why

Current FSM mode switching between Single (SRT), Drum Mode (DM), and Drum Window (DW) is inconsistent and uses cyclical transitions that can lead to confusion. Modes can implicitly influence each other, and some switching paths (like DW -> DM) are blocked or non-intuitive. Users need a strict, predictable way to activate specific modes without unexpected toggles or state leakage.

## What Changes

- **BREAKING**: Change `z` (я) to strictly activate `DW` mode (toggles with `SRT`).
- **BREAKING**: Change `x` (ч) to strictly activate `DM` mode (toggles with `SRT`).
- Allow direct switching between `DW` and `DM` modes without returning to `SRT` first.
- Harmonize internal FSM states to ensure clean separation between `SRT`, `DM`, and `DW` modes.
- Implement an "Ignore List" for accidental key presses during intensive immersion sessions to prevent accidental context switching.

## Capabilities

### New Capabilities
- `key-ignore-list`: Support for ignoring specific keys in `input.conf` to prevent accidental triggers.

### Modified Capabilities
- `immersion-engine`: Coordinate FSM states and switching logic between SRT, DM, and DW.
- `global-navigation-bindings`: Update and coordinate keyboard shortcuts (z/x) for mode switching.

## Impact

- `scripts/lls_core.lua`: Significant changes to mode toggle functions and FSM state management.
- `input.conf`: Updates to key bindings and additions to the ignore list.
- User Experience: More predictable mode switching and protection against accidental key presses.
