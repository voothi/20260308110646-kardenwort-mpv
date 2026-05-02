## ADDED Requirements

### Requirement: Configurable Clipboard Retry Logic
The system SHALL provide user-configurable parameters to control the Windows clipboard retry mechanism to ensure compatibility with background dictionary tools.

#### Scenario: Adjusting retry count
- **WHEN** the user sets `win_clipboard_retries` to 10 in `mpv.conf`.
- **THEN** the system SHALL attempt to set the clipboard up to 10 times before failing.

#### Scenario: Adjusting retry delay
- **WHEN** the user sets `win_clipboard_retry_delay` to 100 in `mpv.conf`.
- **THEN** the system SHALL wait 100ms between failed clipboard attempts.

### Requirement: Robust Unicode Support via PowerShell
The system SHALL maintain UTF-8 encoding for all clipboard operations on Windows, even when using retry logic.

#### Scenario: Copying Cyrillic or special characters
- **WHEN** the user copies text containing non-ASCII characters (e.g., "Привет").
- **THEN** the clipboard SHALL contain the correctly encoded UTF-8 string regardless of whether retries were triggered.
