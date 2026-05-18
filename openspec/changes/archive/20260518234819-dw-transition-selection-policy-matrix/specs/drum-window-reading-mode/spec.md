## ADDED Requirements

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
