## ADDED Requirements

### Requirement: Cross-Process Clipboard Bridging
The system SHALL support pasting text from the system clipboard into the search buffer using PowerShell integration.

#### Scenario: Pasting into search bar
- **WHEN** the user presses `Ctrl+V` (or `Ctrl+М`) while the search bar is active
- **THEN** the system SHALL execute `Get-Clipboard` via PowerShell and append the result to the current search query.
