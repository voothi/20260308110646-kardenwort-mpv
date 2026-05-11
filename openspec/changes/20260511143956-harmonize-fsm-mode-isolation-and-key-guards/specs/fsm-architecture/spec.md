## ADDED Requirements

### Requirement: Main Mode Ownership Isolated
The system SHALL enforce isolated ownership boundaries between `srt`, `dm`, and `dw` so mode-local actions cannot mutate unrelated mode state.

#### Scenario: SRT mode cannot mutate DW copy state
- **GIVEN** `DRUM=OFF` and `DRUM_WINDOW=OFF`
- **WHEN** a DW-only copy-mode toggle command is triggered
- **THEN** `FSM.COPY_MODE` SHALL remain unchanged
- **AND** a non-fatal feedback message SHALL indicate DW-only scope.

#### Scenario: SRT mode cannot mutate DW context-copy state
- **GIVEN** `DRUM=OFF` and `DRUM_WINDOW=OFF`
- **WHEN** a DW-only context-copy toggle command is triggered
- **THEN** `FSM.COPY_CONTEXT` SHALL remain unchanged
- **AND** a non-fatal feedback message SHALL indicate DW-only scope.

### Requirement: Interactive Binding Activation Matches Mode
DW interaction bindings SHALL only be active in modes that own interactive DW/DM behavior.

#### Scenario: Plain SRT does not activate DW binding bundle
- **GIVEN** `DRUM=OFF`, `DRUM_WINDOW=OFF`
- **WHEN** interactive bindings are refreshed
- **THEN** DW keyboard/mouse forced bindings SHALL NOT be active.

#### Scenario: DM keeps interactive bindings
- **GIVEN** `DRUM=ON`, `DRUM_WINDOW=OFF`
- **WHEN** interactive bindings are refreshed
- **THEN** the DW/DM interaction binding bundle SHALL be active.
