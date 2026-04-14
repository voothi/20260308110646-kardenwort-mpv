## Context

The Drum Window (handling EN/RU modes) manages transient keybindings. Prior to this change, there was no shortcut to open the active TSV record file (where Anki exports are stored), forcing users to manually navigate the filesystem to review their data.

## Goals / Non-Goals

**Goals:**
- Provide a one-key shortcut ('o'/'щ') to open the current TSV record file while in the Drum Window.
- Allow the editor to be configurable via `mpv.conf`.
- Ensure the launch is non-blocking and doesn't disrupt the Drum Window UI.
- Suppress mpv's default 'o' behavior (OSD cycle) to prevent UI conflicts.

**Non-Goals:**
- Implementing a built-in TSV viewer or editor.

## Decisions

- **Configurable Editor**: Added `record_editor` to the `Options` table in `lls_core.lua` and registered it in `mpv.conf`. This allows users to specify their preferred editor (e.g., VS Code).
- **Global Binding Override**: Mapped `o` and `щ` in `input.conf` to a script-binding `toggle-record-file`. This suppresses the native mpv `o` behavior and allows the script to route the command based on the Drum Window's current state.
- **Asynchronous Execution**: Used `mp.command_native_async` with the `subprocess` name and `detach = true`. This prevents the Lua thread from blocking during process startup, which was previously causing the Drum Window UI to collapse.
- **Logging**: Added `mp.msg.info` logging to provide clear status in the mpv console/terminal for easier troubleshooting.

## Risks / Trade-offs

- **Path Configuration**: Users must ensure the `record_editor` path in `mpv.conf` is correct for their system.
- **Process Persistence**: Using `detach = true` ensures the editor remains open even if mpv is closed, but it means mpv cannot track the editor's lifecycle.
