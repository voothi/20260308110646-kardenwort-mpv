## ADDED Requirements

### Requirement: Multi-Input Jitter Resilience
The system SHALL prioritize explicit keyboard navigation over implicit mouse activity when both occur in a narrow temporal window to ensure 100% stability for remote control devices.

#### Scenario: Mouse Interaction Shielding
- **WHEN** any keyboard-bound Drum Window shortcut (e.g., `t`) is triggered
- **THEN** the system SHALL activate an interaction shield that ignores all incoming mouse button events for a duration of at least 150ms.
- **AND** this shield SHALL prevent accidental hardware "ghost clicks" from moving the yellow focus cursor or disrupting the active selection.
