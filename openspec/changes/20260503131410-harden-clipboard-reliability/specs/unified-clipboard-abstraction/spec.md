## MODIFIED Requirements

### Requirement: Layout-Agnostic Dictionary Trigger
The `set_clipboard(text, mode)` function SHALL explicitly notify the dictionary tool using a layout-independent mechanism (e.g., Virtual Key signals) to ensure reliable operation across EN/RU keyboard layouts.

#### Scenario: Multi-layout popup trigger
- **WHEN** the user is in Russian layout and triggers a "side" copy
- **THEN** the system SHALL send the raw VK signal for `Ctrl+Alt+Shift+Q` without typing the character `й`

### Requirement: Unified Multi-Mode Configuration
The system SHALL expose a consistent `gd_` prefix for all dictionary-related settings in `mpv.conf`, supporting independent hotkeys for "Popup" and "Main Window" modes.

#### Scenario: Independent mode triggering
- **WHEN** `gd_hotkey_popup` and `gd_hotkey_main` are configured
- **THEN** the system SHALL dispatch the corresponding notification signal based on the copy command context (`side` vs. `main`)
