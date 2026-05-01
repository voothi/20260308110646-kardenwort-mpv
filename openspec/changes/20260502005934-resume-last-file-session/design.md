## Context

MPV provides a `save-position-on-quit` option which remembers the timestamp within a specific file, but it does not natively remember the last file played and reload it upon a blank application launch. This creates a disconnect in the immersion workflow for users who frequently close and reopen the player.

## Goals / Non-Goals

**Goals:**
- Create a lightweight, independent Lua script to manage session persistence.
- Implement a robust filesystem-based state tracking mechanism.
- provide high-visibility, "Premium" OSD feedback that identifies loaded tracks.

**Non-Goals:**
- Modifying the core `mpv.exe` binary.
- Implementing a full playlist history/manager (only the single last file is tracked).
- Modifying existing `lls_core.lua` logic.

## Decisions

- **State Persistence Location**: Use `~~/resume_session.state` (standard MPV config directory) to ensure the script remains portable and avoids cluttering the user's home directory.
- **Temporary OSD Property Overrides**: Use `mp.set_property("osd-font-size", ...)` instead of ASS tags for the startup message. 
    - *Rationale*: Native OSD properties are more reliable across varied user configurations than ASS tags, which can be disabled or misinterpreted depending on `osd-ass-cc` settings.
- **Startup Delay (0.1s)**: Implement a 100ms timeout on script initialization before checking the playlist.
    - *Rationale*: This prevents the script from accidentally loading the last file when a new file was actually provided as a command-line argument but hasn't yet been fully registered in the `path` property.
- **Subtitle Priority Sorting**: Force `.ru.` extensions to the end of the list.
    - *Rationale*: In the Kardenwort ecosystem, Russian is typically the secondary/support language. Sorting it to the bottom ensures the primary target language (English/German/etc.) stays at the visual anchor point.

## Risks / Trade-offs

- **Risk**: File path changes (moving/renaming the video).
    - **Mitigation**: Implement `utils.file_info` check before calling `loadfile`. If the file is missing, log a warning and remain idle.
- **Risk**: Concurrent OSD messages.
    - **Mitigation**: The font size restoration is handled via a `mp.add_timeout` that matches the message duration, minimizing the window where other OSD elements might be affected by the temporary size change.
