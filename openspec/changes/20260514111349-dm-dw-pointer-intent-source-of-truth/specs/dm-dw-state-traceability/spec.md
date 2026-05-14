## ADDED Requirements

### Requirement: Pointer Intent Traceability
DM/DW traceability SHALL include explicit pointer-intent lifecycle checkpoints for boundary-accurate activation.

#### Scenario: Pointer-intent checkpoints are auditable
- **WHEN** DM/DW pointer behavior is validated after Esc clear or live activation
- **THEN** traceability SHALL reference intent snapshot resolution, event-type gating, and desync-rebase decisions
- **AND** these checkpoints SHALL be mappable to runtime-observable state transitions.

### Requirement: Runtime Boundary Regression Gate
The DM/DW acceptance checklist SHALL include boundary-time runtime tests for activation accuracy.

#### Scenario: Runtime edge validation required
- **WHEN** regression validation is executed for DM/DW state behavior
- **THEN** the checklist SHALL include runtime (IPC/live playback) scenarios where activation occurs near subtitle start boundaries
- **AND** passing only structural source-pattern tests SHALL be insufficient for completion.
