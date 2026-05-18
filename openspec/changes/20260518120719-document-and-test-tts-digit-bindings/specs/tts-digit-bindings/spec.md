## ADDED Requirements

### Requirement: Configurable TTS Hotkeys and Triggers
The system MUST support up to 8 configurable Text-to-Speech (TTS) hotkeys and trigger keys. The feature MUST be toggleable via `tts_trigger_enabled`. Each trigger key (e.g., `key_tts_1` through `key_tts_8`) maps to a system-wide hotkey (e.g., `tts_hotkey_1` through `tts_hotkey_8`).

#### Scenario: TTS Digit Configuration
- **WHEN** `tts_trigger_enabled` is set to `yes`
- **AND** `key_tts_2` is set to `2` and `tts_hotkey_2` is set to `Ctrl+Alt+Shift+2`
- **THEN** the system MUST register the key `2` to trigger the subtitle copying and virtual key injection process.

### Requirement: Layout-Independent VK TTS Trigger Injection
To ensure high-speed operation that bypasses keyboard layout and active language modifiers, the TTS trigger mechanism MUST programmatically inject hardware Virtual Key (VK) codes corresponding to the mapped hotkeys.

#### Scenario: Virtual Key Injection for TTS
- **WHEN** the user presses configured key `2`
- **THEN** the system MUST copy the subtitle text
- **AND** it MUST inject the Virtual Key codes for `Ctrl`, `Alt`, `Shift`, and physical key `2` to trigger the external TTS tool layout-independently.

### Requirement: Digit Compatibility and Ignore Overrides
To permit the script-level bindings to capture the digit key presses, any digit configured as an active TTS key MUST NOT be hard-ignored in the standard keyboard configuration file (`input.conf`). Unconfigured digits MUST remain ignored or assigned to other operations.

#### Scenario: Active Digit Ignore Bypass
- **WHEN** `key_tts_2` is active with value `2`
- **THEN** `input.conf` MUST NOT contain the line `2 ignore`
- **AND** inactive digits like `1` or `6` MUST be explicitly ignored (e.g., `1 ignore`, `6 ignore`).

### Requirement: TTS Help HUD Integration
All active TTS digit bindings MUST be documented in `input.conf` using `@help` comments so that they are dynamically parsed and displayed in the F1 Help HUD interface.

#### Scenario: Help HUD Display for TTS Bindings
- **WHEN** the Help HUD is displayed by pressing `F1`
- **THEN** it MUST display the active TTS digit bindings (e.g., `copy-subtitle-tts-2 | TTS EN (copy + trigger) | 2`) under the correct HUD section.
