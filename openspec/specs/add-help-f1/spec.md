# Capability: Dynamic Help HUD (F1)

The system must provide a dynamic, scrollable shortcut reference overlay (Help HUD) that automatically discovers active keybindings and allows user-defined overrides and styling.

## Requirements

### Requirement: Dynamic Binding Discovery
The HUD must query the active `input-bindings` at runtime to ensure the displayed shortcuts are accurate to the user's current configuration.

#### Scenario: Discovering custom volume keys
- **WHEN** the user has bound `9` and `0` to volume control in `input.conf`
- **THEN** the Help HUD should automatically display "9 0" next to "Adjust Volume"

### Requirement: UTF-8 Aware Key Notation (Cyrillic Support)
The system must transform raw key names into professional notation (`Shift+letter`), correctly handling multi-byte UTF-8 Cyrillic characters.

#### Scenario: Normalizing Cyrillic shortcuts
- **WHEN** a binding for `Й` (uppercase) is found
- **THEN** the HUD must display `Shift+й` (lowercase)
- **AND** it must correctly map both `D0` and `D1` UTF-8 blocks to avoid encoding artifacts

### Requirement: Config-Driven Metadata (@help tags)
Users must be able to override descriptions and whitelists directly in `input.conf` using a standardized comment format.

#### Scenario: Overriding a description in input.conf
- **GIVEN** a line `# @help: volume | Master Volume | 9, 0`
- **WHEN** the HUD is rendered
- **THEN** it must use "Master Volume" as the description instead of the script default

### Requirement: Externalized Visual Styling
All visual parameters (colors, font, opacity) must be exposed via `mp.options` to allow global customization without script modification.

#### Scenario: Customizing shortcut color
- **WHEN** `help_key_color` is set to `00CCFF` in `script-opts/kardenwort.conf`
- **THEN** all key combinations in the HUD must be rendered in Gold/Yellow

### Requirement: Global Input Filtering
The discovery engine must suppress technical "noise" (mouse buttons, wheels) globally unless explicitly whitelisted for a specific action to maintain UI clarity.

#### Scenario: Hiding mouse buttons from volume
- **WHEN** `WHEEL_UP` is bound to volume
- **AND** it is not in the `Adjust Volume` whitelist
- **THEN** it should be hidden from the HUD display
