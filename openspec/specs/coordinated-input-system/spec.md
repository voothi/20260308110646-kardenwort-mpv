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
- **THEN** it SHALL read `dw_key_add`, `dw_key_pair`, `dw_key_tooltip_pin`, `dw_key_tooltip_hover`, `dw_key_tooltip_toggle`, `dw_key_cycle_copy_mode`, and `dw_key_toggle_copy_context` from the Options table.

### Requirement: Layout-Aware Binding
The system SHALL allow multiple physical keys (e.g., from different keyboard layouts) to be mapped to the same logical action within a single configuration list.

#### Scenario: EN and RU layout parity
- **WHEN** the list contains both `r` and `к`
- **THEN** the smart-add action MUST work regardless of the active keyboard layout.

### Requirement: Unified Mode Toggles
The keys `z` and `x` SHALL be responsive in all UI states, including the Drum Window and Book Mode.

#### Scenario: Toggling Context Copy in Book Mode
- **WHEN** the Drum Window is open and Book Mode is ON.
- **THEN** pressing `x` SHALL toggle `FSM.COPY_CONTEXT` and display an OSD message "Context Copy: ON/OFF".

#### Scenario: Cycling Copy Mode in Book Mode
- **WHEN** the Drum Window is open and Book Mode is ON.
- **THEN** pressing `z` SHALL cycle `FSM.COPY_MODE` and display the corresponding OSD message.

### Requirement: Coordinated Tooltip Keys Across Drum and DW
The coordinated key system SHALL route configured tooltip keys to the correct mode-specific tooltip handler while preserving a single logical key configuration surface.

#### Scenario: Drum Mode routing
- **WHEN** a configured tooltip key is triggered and `FSM.DRUM == "ON"` with `FSM.DRUM_WINDOW == "OFF"`
- **THEN** the key SHALL dispatch to the Drum Mode tooltip handler
- **AND** it SHALL NOT invoke Drum Window tooltip handlers in the same event.

#### Scenario: Drum Window routing
- **WHEN** a configured tooltip key is triggered and `FSM.DRUM_WINDOW == "DOCKED"`
- **THEN** the key SHALL dispatch to Drum Window tooltip handlers according to existing DW contracts.

### Requirement: Layout-Parity Tooltip Triggers
Configured multi-key lists for tooltip actions SHALL preserve keyboard-layout parity in Drum Mode.

#### Scenario: EN/RU tooltip key parity
- **WHEN** tooltip trigger options include multiple physical-key variants for the same logical action
- **THEN** each configured key variant SHALL activate the same Drum tooltip behavior.

