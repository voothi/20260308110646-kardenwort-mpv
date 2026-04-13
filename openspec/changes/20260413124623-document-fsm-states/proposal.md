## Why

The `lls_core.lua` engine has grown more complex, managing multiple interacting states (Drum Mode, Drum Window, Autopause, Tooltips, Global Search). Currently, the finite state machine (FSM) state combinations and transition logic are managed implicitly in the script without explicit documentation. A thorough, formalized architectural specification of all FSM chains, visibility toggles, and state boundaries is needed so that future modifications (especially by AI models or contributors) do not introduce regressions such as flickering or conflicting state overrides.

## What Changes

- Create a comprehensive new specification that formally documents the FSM table in `lls_core.lua`.
- Document all core states (`MEDIA_STATE`, `DRUM`, `DRUM_WINDOW`, `AUTOPAUSE` etc.).
- Detail state transitions, how they combine (e.g., how the Drum Window hides native and Drum OSD subtitles, how SRT OSD mode impacts visibility flags).
- **Resolve known regressions:** Fix the bug where closing Drum Mode failed to cleanly restore Regular SRT mode, and fix the "Duplicate Secondary Subtitle" artefact caused when pressing `j` in Drum Mode (`master_tick` failing to evaluate `secondary-sub-visibility`).

**Chat Anchors for context:**
- `20260413123223`: Mode switching bug reported.
- `20260413123542` & `20260413123947`: Drum window 'w' visibility combat with regular SRT.
- `20260413124623` & `20260413125428`: Specifications formally proposed and legacy baseline `4d71703` referenced.
- `20260413130213`: Duplicate secondary subtitle artifact bug reported.

## Capabilities

### New Capabilities
- `fsm-architecture`: A comprehensive architectural specification defining the finite state machine governing the subtitle interface, outlining all state schemas, interaction matrices, and mode transitions.

### Modified Capabilities
- None.

## Impact

- Corrects critical overlap bugs (multiple subtitles rendering at once) by hardening `master_tick`.
- Future codebase updates will reference this specific documentation to maintain architectural integrity and prevent infinite rendering loops or flag fighting.
