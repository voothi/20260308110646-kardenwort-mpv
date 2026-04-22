# keybinding-consolidation Specification

## Purpose
TBD - created by archiving change 20260310024112-release-v1-2-6. Update Purpose after archive.
## Requirements
### Requirement: Deferment to `input.conf`
The system SHALL NOT hardcode default physical keys within the script logic for any command intended to be user-configurable.

#### Scenario: Registering a command
- **WHEN** the system registers the `toggle-drum-mode` command
- **THEN** it SHALL use `nil` as the default key binding, requiring an explicit entry in `input.conf` for activation.

### Requirement: Exclusive Authority
The `input.conf` file SHALL be the exclusive authority for mapping physical keys to script-defined commands.

#### Scenario: Rebinding a key
- **WHEN** the user changes a binding in `input.conf`
- **THEN** the system SHALL respect the new binding without interference from hardcoded script defaults.

