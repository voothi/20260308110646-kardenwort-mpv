## MODIFIED Requirements

### Requirement: Low-Latency Clipboard Setting
The `set_clipboard(text)` function SHALL utilize the fastest available platform-specific method (e.g., MPV native `clipboard` property) before falling back to shell-based utilities.

#### Scenario: Native clipboard update
- **WHEN** the host environment supports a native clipboard API
- **THEN** the system SHALL update the clipboard without spawning a shell process

### Requirement: Explicit Post-Copy Hooks
The system SHALL support an optional hook to trigger a keyboard shortcut (e.g., GoldenDict scan popup) immediately after a successful clipboard update.

#### Scenario: Automatic GoldenDict trigger
- **WHEN** `lls-goldendict_trigger` is enabled
- **THEN** the system SHALL send `^!+n` after `set_clipboard` completes
