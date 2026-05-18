## Purpose
Defines Drum Window follow/manual reading behavior and seek-driven synchronization between viewport focus and playback state.
## Requirements
### Requirement: Viewport Decoupling
The system SHALL support a **Manual Mode** for the Drum Window where the viewport remains static despite changes in video playback position.

#### Scenario: Navigating in Drum Window
- **WHEN** the user presses a navigation key (`UP`, `DOWN`, `LEFT`, `RIGHT`) in the Drum Window
- **THEN** the system SHALL enter Manual Mode and freeze the viewport at its current position.

### Requirement: Seek Synchronization Recovery
The system SHALL re-enable **Follow Mode** and synchronize the viewport upon a seek event, with behavior varying by active mode.

#### Scenario: Seeking while in Normal Mode (Book Mode OFF)
- **WHEN** the user executes a seek command (`a` or `d`)
- **THEN** the system SHALL re-enable Follow Mode and re-center the viewport precisely on the new active subtitle.

#### Scenario: Seeking while in Book Mode (ON)
- **WHEN** the user executes a seek command (`a` or `d`)
- **THEN** the system SHALL re-enable Follow Mode but SHALL NOT perform a hard re-center; instead, it SHALL ensure the active subtitle is visible within the current viewport margins (using "Push" or "Paged" logic).

#### Scenario: Manual Seek to Selected Line
- **WHEN** the user jumps to a specific line via cursor selection (`ENTER`)
- **THEN** the system SHALL re-enable Follow Mode if in Normal Mode, but SHALL REMAIN in Manual Mode if in Book Mode to maintain reading focus.

### Requirement: Transition Policy Resolution
The system SHALL resolve follow/manual state after line transition seeks (`Enter` and double-click) using the transition policy matrix, without hard-coded Book Mode overrides.

#### Scenario: Transition in Normal Mode (Book Mode OFF)
- **WHEN** a line transition seek is executed
- **THEN** the resulting follow/manual state SHALL be determined by `dw_esc_mode` and `dw_clear_selection_after_transition`.

#### Scenario: Transition in Book Mode (ON)
- **WHEN** a line transition seek is executed
- **THEN** the resulting follow/manual state SHALL be determined by `dw_esc_mode` and `dw_clear_selection_after_transition`.

#### Scenario: Retained pointer in auto mode
- **WHEN** `dw_esc_mode=auto_follow_current` and `dw_clear_selection_after_transition=no` preserves an active pointer
- **THEN** the system SHALL keep manual mode until pointer clear via Esc.

