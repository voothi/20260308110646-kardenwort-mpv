## Context

MPV natively manages timestamp persistence via `save-position-on-quit`, but lacks the capability to automatically reload the last session upon a blank application launch. This architectural gap forces users into manual file selection, disrupting the continuity of language immersion.

## Goals / Non-Goals

**Goals:**
- Implement a decoupled session manager that tracks and restores the last active media path.
- Provide high-fidelity visual confirmation of resumed assets using the core LLS design language.
- Ensure cross-platform reliability for both local and URL-based media.

**Non-Goals:**
- Modifying the primary `lls_core.lua` script or the MPV binary.
- Implementing a multi-file playlist history (focus remains on the singleton "last session").

## Decisions

- **Storage Strategy**: Utilize `~~/resume_session.state` within the MPV configuration directory to centralize session data in a predictable, portable location.
- **High-Resolution OSD Overlay**: Implement `mp.create_osd_overlay` with a fixed `1920x1080` virtual canvas.
    - *Rationale*: Standard OSD property manipulation (`osd-font-size`) proved inconsistent across varied display resolutions. A high-res overlay ensures identical typography and layout synchronization with the primary `lls_core` UI.
- **ASS Formatting Logic**: Employ `{\an7}` for top-left anchoring combined with `\N` forced newlines and explicit `\bord` (border) and `\shad` (shadow) tags.
    - *Rationale*: This guarantees consistent rendering of multi-line filenames and subtitle tracks while providing "Premium" depth and legibility.
- **Race Condition Mitigation**: Enforce a 100ms startup delay before session validation.
    - *Rationale*: This allows the primary player process to register any command-line arguments, preventing the auto-resume logic from overwriting an intended manual file load.
- **Linguistic Prioritization**: Implement a custom sort predicate that pushes `.ru.` (Russian) subtitle tracks to the bottom of the OSD column.
    - *Rationale*: In the immersion workflow, the target language (Main) must be the primary visual anchor, with the translation (Secondary) relegated to a supportive position.

## Risks / Trade-offs

- **Risk**: Stale paths (moved or deleted files).
    - **Mitigation**: Perform a non-blocking `utils.file_info` check before invoking `loadfile`.
- **Risk**: OSD Layering.
    - **Mitigation**: Assign the session OSD to a high Z-index (managed layer) and ensure clean removal via `mp.add_timeout` after the display window expires.
