## Why

To improve the continuity of language immersion sessions by eliminating the need to manually locate and reload the last video file and its associated subtitle tracks every time MPV is launched. Currently, starting MPV without a file argument results in a blank interface, creating friction for users who consume content in multiple sessions.

## What Changes

- **Core Scripting**: Implementation of `resume_last_file.lua` as a standalone session manager.
- **Session Persistence**: Automated recording of absolute media paths to `~~/resume_session.state`.
- **Intelligent Auto-Resume**: Detection of empty startup states to trigger automatic restoration of the previous session.
- **Premium OSD Diagnostic**: A high-resolution OSD overlay (1920x1080) that displays a clean, vertical column of the resumed video and its connected subtitle tracks.
- **Subtitle Prioritization**: Logic to detect and sort sidecar subtitles, ensuring target languages (Main) are anchored above support languages (Secondary/Russian).
- **Aesthetic Synchronization**: Alignment of OSD typography (Consolas, Size 34) and styling (Border/Shadow) with the core LLS UI standard.
- **Configurable Control Plane**: Exposure of granular options for font sizing, naming, display duration, and visibility toggles.

## Capabilities

### New Capabilities
- `session-persistence`: Automated tracking and restoration of the primary media session.
- `startup-diagnostic-osd`: High-fidelity visual reporting of loaded assets and detected sidecar subtitle tracks.

### Modified Capabilities
- None

## Impact

- **Affected Codebase**: Addition of `scripts/resume_last_file.lua`.
- **User Interface**: New startup feedback overlay providing immediate session context.
- **Workflow Efficiency**: Reduction in the number of manual steps required to initiate a study session.
