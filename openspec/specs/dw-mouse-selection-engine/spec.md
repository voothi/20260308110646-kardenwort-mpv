## Purpose
Defines Drum Window mouse selection interaction, hit-testing, dragging responsiveness, and double-click seek behavior.
## Requirements
### Requirement: Unified Layout Hit-Testing
The system SHALL use a pre-calculated layout table to ensure 1:1 mapping between rendered text and mouse click coordinates.

#### Scenario: Clicking a wrapped word
- **WHEN** the user clicks on a word that has been wrapped to a new line
- **THEN** the system SHALL correctly identify the word index by referencing the `dw_build_layout` coordinate table.

### Requirement: Hardware-Accelerated Dragging
The system SHALL bind mouse selection highlights to hardware-level motion events to provide fluid, high-frame-rate feedback.

#### Scenario: Rapidly dragging a selection
- **WHEN** the user drags the mouse to select multiple words
- **THEN** the highlight SHALL update at the player's native frame rate (60fps+) without polling lag.

### Requirement: Reachable Edge-Scroll During Overflow
The system SHALL keep Drum Window drag edge-scroll triggers reachable even when long wrapped subtitles make the rendered text block overflow the OSD frame.

#### Scenario: Dragging from an overflowing top or bottom visual line
- **GIVEN** Drum Window contains long wrapped subtitles whose hit-zones extend beyond the top or bottom OSD boundary
- **WHEN** the user holds LMB and drags through the first visual line upward or the last visual line downward
- **THEN** selection SHALL continue to follow the pointer
- **AND** edge-scroll SHALL use a reachable screen-edge trigger instead of an unreachable off-screen first/last hit-zone boundary.

### Requirement: Double-Click Seek Synchronization
The system SHALL support instant seeking via double-click with viewport synchronization logic that respects the active reading mode.

#### Scenario: Double-clicking in Normal Mode (Book Mode OFF)
- **WHEN** the user double-clicks a visible subtitle line
- **THEN** the system SHALL seek playback to that subtitle's start time, re-enable Follow Mode, re-center the viewport, and CLEAR any active word selection (reset `FSM.DW_CURSOR_WORD` and `FSM.DW_ANCHOR_WORD` to `-1`).

#### Scenario: Double-clicking in Book Mode (ON)
- **WHEN** the user double-clicks a visible subtitle line
- **THEN** the system SHALL seek playback to that subtitle's start time but SHALL REMAIN in Manual Mode (Follow Mode OFF) and SHALL NOT re-center the viewport, preserving the user's current reading position.

### Requirement: Double-Click Transition Parity with Enter
The system SHALL apply the same post-transition selection/follow/neutral-arm policy for double-click seek and Enter seek.

#### Scenario: Equivalent transition outcomes
- **WHEN** identical preconditions are used for Enter and double-click transitions
- **THEN** pointer state, anchor state, follow/manual state, and neutral-arm state SHALL be equivalent.

#### Scenario: Auto mode with pointer retained
- **WHEN** `dw_esc_mode=auto_follow_current` and `dw_clear_selection_after_transition=no`
- **THEN** double-click transition SHALL keep manual mode while pointer remains active, matching Enter behavior.

#### Scenario: Neutral mode transition
- **WHEN** `dw_esc_mode` is `neutral_last_selection` or `neutral_current_subtitle`
- **THEN** double-click transition SHALL remain manual, matching Enter behavior.

