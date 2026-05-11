## MODIFIED Requirements

### Requirement: Exclusive FSM Mode Management
The system SHALL maintain mutually exclusive states for the primary immersion modes: SRT (Single), DM (Drum Mode), and DW (Drum Window).

#### Scenario: Activation of Drum Mode (DM)
- **WHEN** DM is activated via the `toggle-drum-mode` command
- **THEN** DM MUST be set to `ON`
- **AND** DW MUST be set to `OFF` if it was previously active
- **AND** the system MUST transition to SRT if DM was already active (strict toggle to baseline)

#### Scenario: Activation of Drum Window (DW)
- **WHEN** DW is activated via the `toggle-drum-window` command
- **THEN** DW MUST be set to `ON` (DOCKED)
- **AND** DM MUST be set to `OFF` if it was previously active
- **AND** the system MUST transition to SRT if DW was already active (strict toggle to baseline)

#### Scenario: Direct Mode Switching (DW to DM)
- **WHEN** the system is in DW mode
- **AND** the user triggers `toggle-drum-mode`
- **THEN** DW MUST be deactivated
- **AND** DM MUST be activated immediately without intermediate states or "Managed by" blocks

#### Scenario: Direct Mode Switching (DM to DW)
- **WHEN** the system is in DM mode
- **AND** the user triggers `toggle-drum-window`
- **THEN** DM MUST be deactivated
- **AND** DW MUST be activated immediately
