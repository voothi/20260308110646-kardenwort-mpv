## MODIFIED Requirements

### Requirement: Low-Latency Clipboard Setting
The `set_clipboard(text)` function SHALL utilize the fastest available platform-specific method (e.g., MPV native `clipboard` property) before falling back to shell-based utilities.

#### Scenario: Native clipboard update
- **WHEN** the host environment supports a native clipboard API
- **THEN** the system SHALL update the clipboard without spawning a shell process

### Requirement: User-Friendly Hotkey Configuration
The system SHALL allow users to define the GoldenDict trigger hotkey using standard naming (e.g., `Ctrl+Alt+Shift+Q`) in `mpv.conf`, which the script SHALL automatically translate into the internal platform-specific format.

#### Scenario: Custom hotkey trigger
- **WHEN** `lls-goldendict_hotkey` is set to `Ctrl+Alt+Shift+Q`
- **THEN** the system SHALL send the correct `.NET` sequence (`^%+q`) to the OS after copying
