## MODIFIED Requirements

### Requirement: Double-Click Seek Synchronization
The system SHALL support instant seeking via double-click with post-transition synchronization logic that is equivalent to Enter transition behavior.

#### Scenario: Double-clicking in Normal Mode (Book Mode OFF)
- **WHEN** the user double-clicks a visible subtitle line
- **THEN** the system SHALL seek playback to that subtitle's start time and apply the same post-transition selection/follow policy matrix used by Enter.

#### Scenario: Double-clicking in Book Mode (ON)
- **WHEN** the user double-clicks a visible subtitle line
- **THEN** the system SHALL seek playback to that subtitle's start time and apply the same post-transition selection/follow policy matrix used by Enter.

#### Scenario: Transition parity with Enter
- **WHEN** identical mode and selection preconditions are used for Enter and double-click transitions
- **THEN** resulting pointer, anchor, follow/manual, and neutral-arm states SHALL be equivalent.
