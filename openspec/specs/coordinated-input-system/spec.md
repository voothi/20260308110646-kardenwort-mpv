# coordinated-input-system Specification

## Purpose
TBD - created by archiving change 20260419191638-unify-drum-mining-shortcuts. Update Purpose after archive.
## Requirements
### Requirement: Multi-Delimiter List Parsing
The system SHALL support parsing of configuration parameters as lists using spaces, commas, or semicolons as delimiters.

#### Scenario: Space-separated key list
- **WHEN** `dw_key_add` is set to `MBTN_MID r к`
- **THEN** the system SHALL bind all three keys to the smart-add action.

#### Scenario: Comma and semicolon support
- **WHEN** `dw_key_add` is set to `MBTN_MID, r; к`
- **THEN** the system SHALL correctly identify and bind the three distinct tokens.

### Requirement: Standardized dw_key_* Naming
The system SHALL use a standardized `dw_key_` prefix for all Drum Window interaction configuration options.

#### Scenario: Accessing coordinated keys
- **WHEN** the script initializes
- **THEN** it SHALL read `dw_key_add`, `dw_key_pair`, `dw_key_tooltip_pin`, `dw_key_tooltip_hover`, and `dw_key_tooltip_toggle` from the Options table.

### Requirement: Layout-Aware Binding
The system SHALL allow multiple physical keys (e.g., from different keyboard layouts) to be mapped to the same logical action within a single configuration list.

#### Scenario: EN and RU layout parity
- **WHEN** the list contains both `r` and `к`
- **THEN** the smart-add action MUST work regardless of the active keyboard layout.

