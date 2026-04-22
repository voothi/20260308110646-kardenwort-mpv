# hotkey-simplification Specification

## Purpose
TBD - created by archiving change 20260310025029-release-v1-2-8. Update Purpose after archive.
## Requirements
### Requirement: Modifier-Free Study Keys
The system SHALL prioritize single-key, modifier-free shortcuts for core study features to maximize interaction speed.

#### Scenario: Using context copy
- **WHEN** the user presses the `x` key
- **THEN** the system SHALL execute the `toggle-copy-context` command.

### Requirement: Cross-Layout Hotkey Symmetry
The system SHALL map equivalent keys from both English and Russian keyboard layouts to the same script commands.

#### Scenario: Switching to Russian layout
- **WHEN** the user presses the `я` key (equivalent position of `z`)
- **THEN** the system SHALL execute the `cycle-copy-mode` command.

