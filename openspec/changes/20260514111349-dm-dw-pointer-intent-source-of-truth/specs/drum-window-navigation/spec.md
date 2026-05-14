## ADDED Requirements

### Requirement: Intent-Snapshot Activation in DW and DM
DW/DM arrow activation SHALL consume a single resolved navigation-intent snapshot for both Drum Window (`W`) and Drum Mode mini (`C` with `W` closed).

#### Scenario: Null-pointer activation at subtitle boundary
- **WHEN** playback is live and pointer is null (`DW_CURSOR_WORD = -1`)
- **AND** user presses `UP`, `DOWN`, `LEFT`, or `RIGHT` near a subtitle boundary tick
- **THEN** activation SHALL use the intent snapshot's resolved active context for that key intent
- **AND** the yellow pointer SHALL NOT activate from a stale pre-boundary line for the same intent.

### Requirement: Event-Consistent Arrow Semantics
Arrow navigation SHALL apply identical event semantics for EN/RU bindings in DW/DM activation paths.

#### Scenario: EN and RU arrows preserve activation contract
- **WHEN** navigation is triggered by either EN (`UP/DOWN/LEFT/RIGHT`) or RU (`ВВЕРХ/ВНИЗ/ЛЕВЫЙ/ПРАВЫЙ`) bindings
- **THEN** both bindings SHALL follow the same event-type gating and null-activation behavior
- **AND** runtime behavior SHALL remain parity-consistent across both layouts.
