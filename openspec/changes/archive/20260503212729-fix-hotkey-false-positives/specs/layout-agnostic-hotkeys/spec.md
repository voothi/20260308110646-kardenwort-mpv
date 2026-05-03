## ADDED Requirements

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
