## ADDED Requirements

### Requirement: Timeline-Bounded Seek Boundaries
The custom seeking navigation SHALL be restricted to the active duration of the dynamic timeline when playing virtual background tracks.

#### Scenario: Bound enforcement
- **WHEN** the user seeks forward near the end of the subtitle timeline
- **THEN** seeking SHALL remain constrained inside the dynamic length bounds rather than returning a seek error
