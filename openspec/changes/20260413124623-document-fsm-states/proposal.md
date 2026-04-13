## Why

The `lls_core.lua` engine has grown more complex, managing multiple interacting states (Drum Mode, Drum Window, Autopause, Tooltips, Global Search). Currently, the finite state machine (FSM) state combinations and transition logic are managed implicitly in the script without explicit documentation. A thorough, formalized architectural specification of all FSM chains, visibility toggles, and state boundaries is needed so that future modifications (especially by AI models or contributors) do not introduce regressions such as flickering or conflicting state overrides.

## What Changes

- Create a comprehensive new specification that formally documents the FSM table in `lls_core.lua`.
- Document all core states (`MEDIA_STATE`, `DRUM`, `DRUM_WINDOW`, `AUTOPAUSE` etc.).
- Detail state transitions, how they combine (e.g., how the Drum Window hides native and Drum OSD subtitles, how SRT OSD mode impacts visibility flags).
- No actual code logic will be fundamentally altered in this change; this is purely an architectural classification and documentation effort to harden the project structure.

## Capabilities

### New Capabilities
- `fsm-architecture`: A comprehensive architectural specification defining the finite state machine governing the subtitle interface, outlining all state schemas, interaction matrices, and mode transitions.

### Modified Capabilities
- None.

## Impact

- No functional code logic changes are strictly mandated by this proposal, but future codebase updates will reference this specific documentation to maintain architectural integrity.
