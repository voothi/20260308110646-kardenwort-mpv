# drum-scroll-sync Specification

## Purpose
TBD - created by archiving change 20260506164500-drum-scroll-sync-hardening. Update Purpose after archive.
## Requirements
### Requirement: Dual-Lane Drum Scroll Synchronization
When manual drum scrolling is active, lower and upper subtitle lanes SHALL move in synchronized viewport context.

#### Scenario: Primary-only scroll behavior
- **GIVEN** only primary subtitles are active
- **WHEN** the user scrokardenwort in drum mode
- **THEN** the viewport SHALL scroll relative to the active primary index
- **AND** manual scroll state SHALL remain stable until explicit follow-player reset.

#### Scenario: Dual-track synchronized scroll
- **GIVEN** primary and secondary subtitle tracks are both active
- **AND** manual viewport mode is active (`DW_FOLLOW_PLAYER == false`)
- **WHEN** the user scrokardenwort by one step
- **THEN** both lanes SHALL shift by an equivalent logical viewport offset
- **AND** neither lane SHALL remain pinned to playhead-follow mode independently.

#### Scenario: Secondary-only fallback
- **GIVEN** only secondary subtitles are active
- **WHEN** the user scrokardenwort in drum mode
- **THEN** the viewport SHALL scroll relative to the active secondary index without requiring a primary index anchor.

### Requirement: Highlight and Active-Line Synchrony During Scroll
Manual viewport scrolling SHALL preserve synchronized visual semantics across both lanes.

#### Scenario: Synchronized emphasis and highlighting
- **GIVEN** highlighted tokens are visible on both subtitle lanes
- **WHEN** the user scrokardenwort the viewport
- **THEN** active-line emphasis SHALL remain tied to each lane's active index
- **AND** semantic highlights SHALL remain tied to their original logical tokens
- **AND** no highlight ownership transfer SHALL occur because of viewport movement.

### Requirement: Explicit Wheel Routing Policy
Wheel behavior outside subtitle hit zones SHALL be explicitly defined and verified.

#### Scenario: Wheel input outside hit zone
- **WHEN** the mouse wheel event occurs outside subtitle hit zones in drum mode
- **THEN** the system SHALL follow the documented policy (pass-through OR consume)
- **AND** implementation behavior SHALL match documentation and tests.

### Requirement: Autopause Invariance Under Scroll-Only Interaction
Manual drum scrolling SHALL NOT change autopause transition semantics.

#### Scenario: Autopause matrix invariance
- **GIVEN** any combination of `AUTOPAUSE` (`ON` or `OFF`) and `IMMERSION_MODE` (`MOVIE` or `PHRASE`)
- **WHEN** the user performs only manual viewport scrolling (no seek, no play/pause toggle)
- **THEN** autopause transition state SHALL remain unchanged except for normal time-driven progression
- **AND** no synthetic seek or boundary transition SHALL be introduced by scroll handling.

### Requirement: Regression Baseline Against 4c634ed
The change SHALL be validated against baseline commit `4c634ed422844c475293dac07bad7d149e9f9df8` to prevent drum-scroll and FSM regressions.

#### Scenario: Regression checklist execution
- **WHEN** validating this change
- **THEN** the following checklist SHALL be executed and recorded:
- `tick_drum` still separates `view_center` and `active_idx` semantics.
- Wheel routing behavior outside hit zones matches the documented policy.
- Dual-track manual scrolling keeps equivalent logical offset between lanes.
- Primary-only and secondary-only fallback scenarios both work as specified.
- Scroll-only interactions do not alter autopause transitions in `MOVIE` or `PHRASE`.

