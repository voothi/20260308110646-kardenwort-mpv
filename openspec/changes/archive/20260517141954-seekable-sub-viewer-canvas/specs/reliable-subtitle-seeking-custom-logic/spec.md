## ADDED Requirements

### Requirement: Timeline-Bounded Seek Boundaries
The custom seeking navigation SHALL be restricted to the active duration of the dynamic timeline when playing virtual background tracks.

#### Scenario: Bound enforcement
- **WHEN** the user seeks forward near the end of the subtitle timeline
- **THEN** seeking SHALL remain constrained inside the dynamic length bounds rather than returning a seek error

### Requirement: Primary-Driven Timing For Paired Reader Tracks
When generating dual reader subtitles from two text files, the final track timing MUST be derived from the primary stream and reused for secondary cues.

#### Scenario: Paired text synchronization
- **WHEN** primary and secondary reader tracks are built from text files
- **THEN** cue timecode boundaries in the secondary output SHALL match primary boundaries exactly
- **AND** only cue text content SHALL differ between tracks

## Discussion Anchors
- `20260517162045` use primary timecodes as canonical timing source
- `20260517160256` duration heuristic quality expectations
