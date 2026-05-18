## ADDED Requirements

### Requirement: Transition-Era Esc Arm Consistency
The system SHALL reset neutral-arm state after transition seeks and re-arm only through explicit Esc interaction.

#### Scenario: Neutral arm cleared after transition
- **WHEN** transition seek (`Enter` or double-click) executes under any Esc mode
- **THEN** `DW_ESC_NEUTRAL_ARMED` SHALL be false immediately after transition.

#### Scenario: Auto mode retained-pointer workflow
- **WHEN** `dw_esc_mode=auto_follow_current` and transition keeps pointer (`dw_clear_selection_after_transition=no`)
- **THEN** follow SHALL stay manual until Esc clears pointer, after which follow SHALL restore.

#### Scenario: Neutral mode remains manual
- **WHEN** `dw_esc_mode` is `neutral_last_selection` or `neutral_current_subtitle`
- **THEN** transition SHALL remain manual and Esc arming SHALL start from a clean post-transition neutral-arm state.
