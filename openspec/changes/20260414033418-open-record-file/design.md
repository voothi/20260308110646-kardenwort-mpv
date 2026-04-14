## Context

The Drum Window (handling EN/RU modes) manages transient keybindings via the `manage_dw_bindings` function. Currently, there is no shortcut to open the generated TSV record file directly.

## Goals / Non-Goals

**Goals:**
- Provide a one-key shortcut ('o'/'щ') to open the current TSV record file while in the Drum Window.
- Ensure the file opens in the default OS editor (minimizing friction for reviewing exports).
- Provide feedback to the user via OSD.

**Non-Goals:**
- Implementing a built-in TSV viewer or editor.
- Opening multiple files or managing file history.

## Decisions

- **Command Implementation**: Create `cmd_open_record_file` which retrieves the path via existing `get_tsv_path()`.
- **OS Interaction**: Use `utils.subprocess_detached` with `powershell Start-Process` to launch the default editor for the TSV file on Windows. This is non-blocking and uses the system's own file associations.
- **Keybinding Integration**: Add entries to the `keys` table within `manage_dw_bindings` to ensure the shortcut is only active when the Drum Window is open and cleaned up when closed.

## Risks / Trade-offs

- **PowerShell Dependency**: Relies on PowerShell being available, which is guaranteed on the user's Windows 11 system.
- **File Existence**: If the TSV file hasn't been created yet (no exports made), the command will fail gracefully with an OSD message.
