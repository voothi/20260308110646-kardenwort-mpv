## ADDED Requirements

### Requirement: DM/DW State Traceability
The project SHALL maintain a canonical traceability specification for DM/DW state transitions affected by Esc staged clearing, pointer activation, seek/scroll synchronization, and Book Mode parity.

#### Scenario: Anchor-chain capture
- **WHEN** a multi-step regression/fix chain spans multiple anchors
- **THEN** the traceability spec SHALL record:
- state variables involved,
- final transition post-conditions,
- cross-mode parity rules,
- acceptance checklist for non-regression.

#### Scenario: Esc-follow and pointer-source traceability
- **WHEN** Stage 3 Esc behavior and null-pointer activation semantics are updated
- **THEN** the traceability capability SHALL explicitly map runtime behavior to the governing requirements in:
- `drum-window`,
- `drum-window-navigation`,
- `book-mode-navigation`.
