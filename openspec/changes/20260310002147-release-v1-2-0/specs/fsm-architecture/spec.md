## ADDED Requirements

### Requirement: State-Driven Mode Management
The system SHALL determine its active operating mode (MEDIA_STATE) by dynamically parsing the current `track-list` of the media player.

#### Scenario: Detecting dual-language tracks
- **WHEN** the media player has both a primary and secondary subtitle track active
- **THEN** the system SHALL enter the `DUAL_ASS` or `DUAL_SRT` (or mixed) state as appropriate.

### Requirement: Consolidated Logic Core
The system SHALL centralize all core language learning features (Autopause, Context visualization, and Subtitle Copy) into a singular script architecture (`lls_core.lua`).

#### Scenario: Feature coordination
- **WHEN** multiple features are enabled simultaneously
- **THEN** their logic SHALL be executed sequentially within the centralized core to prevent race conditions.
