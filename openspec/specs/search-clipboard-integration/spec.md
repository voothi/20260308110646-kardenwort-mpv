## ADDED Requirements

### Requirement: Cross-Platform Clipboard Bridging
The system SHALL support bridging the internal search buffer with the system clipboard across all supported platforms (Windows, macOS, Linux, and Android/Termux).

#### Scenario: Pasting into search bar
- **WHEN** the user presses `Ctrl+V` (or `Ctrl+М`) while the search bar is active
- **THEN** the system SHALL detect the current platform and execute the appropriate utility (e.g., PowerShell `Get-Clipboard` on Windows, `pbpaste` on macOS, `wl-paste` or `xclip` on Linux) to retrieve and append text to the query.
