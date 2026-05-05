## Why

Currently, the Immersion Mode (Phrase vs Movie) is hardcoded to `PHRASE` at startup. Users who prefer `MOVIE` mode must manually toggle it every time they launch a video, which creates unnecessary friction in their immersion workflow.

## What Changes

- **Configurability**: Introduced a new script option `immersion_mode_default` that allows users to specify the starting state in `mpv.conf`.
- **State Initialization**: Updated the core FSM to respect the user-defined default during the script's boot sequence.
- **Documentation**: Updated `README.md` and `mpv.conf` to reflect the new parameter.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `fsm-architecture`: Added a requirement for deterministic startup state for Immersion Modes.
- `centralized-script-options`: Added `immersion_mode_default` to the list of exposed parameters for full configuration parity.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (FSM initialization logic).
- **Configuration**: `mpv.conf` (new `lls-immersion_mode_default` key).
- **Documentation**: `README.md` (updated parameter list).
