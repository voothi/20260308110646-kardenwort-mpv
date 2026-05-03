# layout-agnostic-hotkeys Specification

## Purpose
TBD - created by archiving change 20260503203618-layout-agnostic-hotkeys. Update Purpose after archive.
## Requirements
### Requirement: Automatic Russian Layout Expansion
The system MUST automatically register the corresponding Russian layout key whenever an English alphanumeric key or common punctuation is bound.

#### Scenario: Binding Shift+e
- **WHEN** the script binds `Shift+e`
- **THEN** it MUST also bind `Shift+у` and `Shift+У` to the same action.

### Requirement: Layout-Independent GoldenDict Trigger
The Virtual Key (VK) trigger engine MUST support Cyrillic characters by mapping them to their corresponding physical hardware Virtual Key codes.

#### Scenario: Triggering with Russian Hotkey
- **WHEN** the configuration `gd_hotkey_popup` contains `Ctrl+Alt+Shift+т`
- **THEN** the script MUST inject the VK code `0x4E` (N/Т) along with the modifiers.

### Requirement: Multi-Delimiter Hotkey Lists
All trigger-related configuration strings MUST support space, comma, or semicolon as delimiters for multiple hotkeys.

#### Scenario: Multiple Popup Hotkeys
- **WHEN** `gd_hotkey_popup` is set to `Ctrl+Alt+Shift+n Ctrl+Alt+Shift+т`
- **THEN** both hotkeys MUST be fired in sequence during the trigger event.

### Requirement: Strict Shift-Cyrillic Normalization
The hotkey expansion engine MUST register only the uppercase Cyrillic variant for shifted English keys to prevent collision with unshifted physical key presses.

#### Scenario: Binding Shift+e
- **WHEN** the script binds `Shift+e`
- **THEN** it MUST bind `Shift+e` and `У` (uppercase Cyrillic character)
- **AND** it MUST NOT bind `Shift+у` (lowercase Cyrillic character with Shift modifier)

### Requirement: Granular Diagnostic Tracing
The key registration system MUST provide diagnostic logging that identifies both the physical key pressed and the logical binding triggered when `log_level` is set to `debug`.

#### Scenario: Pressing 'у' in RU Layout
- **WHEN** the physical `E` key is pressed in Russian layout (sending `у`)
- **THEN** the diagnostic log MUST record: `DW TRIGGER: key='у' binding='dw-tooltip-toggle-1'`

