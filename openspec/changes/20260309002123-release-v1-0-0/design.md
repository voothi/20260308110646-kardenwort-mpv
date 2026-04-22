## Context

Release v1.0.0 established the foundation for a script-driven Language Learning Suite. The design focuses on minimizing distractions while providing maximum linguistic context through visual and logic-driven cues.

## Goals / Non-Goals

**Goals:**
- Provide clear visual context for subtitles (Drum Mode) with Middle-Left positioning (`{\an4}`).
- Implement intelligent pause points that respect linguistic boundaries (Autopause).
- Create a non-intrusive, 500ms notification system (Clean OSD).

## Decisions

- **Input Configuration**: All persistent hotkeys are moved to `input.conf` to avoid overwrite bugs and handle multi-layout (EN/RU) keyboards reliably.
- **OSD Rendering**: Uses `mp.osd_message` with `osd-ass-cc/0` instead of `show-text` to ensure reliable ASS tag parsing across different environments.
- **Timing**: Global OSD duration is set to 500ms (`osd_msg_duration`) to maintain a reactive user experience.
- **Hold-to-Play**: Implemented as a `complex=true` handler to allow bypassing all pause points by holding the SPACE key.
- **Script Externalization**: OSD duration is externalized into a configurable `osd_msg_duration` parameter across all active scripts.

## Risks / Trade-offs

- **Risk**: Visual collision in Drum Mode when multiple tracks are active.
- **Mitigation**: Implemented smart stacking and ASS protection to disable Drum Mode on complex files.
- **Risk**: Double-pausing in autopause logic.
- **Mitigation**: Dual-track awareness synchronizes pause points across top and bottom tracks.
