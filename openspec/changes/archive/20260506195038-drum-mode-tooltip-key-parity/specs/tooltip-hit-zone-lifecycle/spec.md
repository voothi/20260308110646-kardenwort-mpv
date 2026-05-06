## ADDED Requirements

### Requirement: Drum Tooltip Hit-Zone Lifecycle Parity
Tooltip interaction metadata SHALL be lifecycle-managed in Drum Mode with the same isolation guarantees used for Drum Window.

#### Scenario: Drum tooltip clear on lifecycle break
- **WHEN** Drum tooltip visual state is cleared due to mouse-out, mode change, or key toggle-off
- **THEN** Drum tooltip hit-zones SHALL be invalidated in the same lifecycle path.

### Requirement: Drum Tooltip Hit-Test Guard
Hit-testing for Drum tooltip interactions SHALL verify Drum tooltip logical activation before accepting a hit-zone result.

#### Scenario: Guarded Drum tooltip hit-test
- **WHEN** a Drum tooltip hit-test is requested while Drum tooltip logical state is inactive
- **THEN** the system SHALL return no tooltip hit result even if stale metadata exists in memory.
