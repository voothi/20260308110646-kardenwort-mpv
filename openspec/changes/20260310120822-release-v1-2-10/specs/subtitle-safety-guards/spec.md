## ADDED Requirements

### Requirement: Mandatory Positional Gap
The system SHALL enforce a minimum 5% vertical gap between the default secondary subtitle position and the default primary subtitle position to prevent visual collision.

#### Scenario: Default positioning
- **WHEN** the system is in the `DUAL` state with default settings
- **THEN** the secondary subtitle SHALL be positioned at Y=90 while the primary remains at Y=95.

### Requirement: Threshold-Based State Detection
The system SHALL use a midpoint threshold to determine the logical "Top" or "Bottom" state of a subtitle track, rather than relying on strict coordinate matching.

#### Scenario: Toggling from custom position
- **WHEN** a subtitle track is positioned at Y=15
- **THEN** the system SHALL recognize it as being in the "Top" state (as 15 < 50) and toggle it to the "Bottom" position correctly.
