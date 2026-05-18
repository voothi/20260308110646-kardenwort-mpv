## ADDED Requirements

### Requirement: Post-Transition Selection Policy Matrix
The system SHALL apply a deterministic matrix after Drum Window transition seek actions (`Enter` and double-click) based on `dw_clear_selection_after_transition` and `dw_esc_mode`.

#### Scenario: Clear policy enabled
- **WHEN** `dw_clear_selection_after_transition=yes` and a transition seek is executed
- **THEN** the system SHALL clear pointer and range/set state (`DW_CURSOR_WORD=-1`, `DW_ANCHOR_LINE=-1`, `DW_ANCHOR_WORD=-1`, ctrl-pending set/list empty).

#### Scenario: Clear policy disabled
- **WHEN** `dw_clear_selection_after_transition=no` and a transition seek is executed
- **THEN** the system SHALL preserve pointer and anchor state at the transitioned selection when a valid pointer exists.

### Requirement: Follow Policy Resolution
The system SHALL resolve follow/manual state after transition based on Esc mode and pointer retention state.

#### Scenario: Auto-follow mode with cleared selection
- **WHEN** `dw_esc_mode=auto_follow_current` and `dw_clear_selection_after_transition=yes`
- **THEN** the system SHALL set follow mode ON immediately after transition.

#### Scenario: Auto-follow mode with preserved pointer
- **WHEN** `dw_esc_mode=auto_follow_current` and `dw_clear_selection_after_transition=no` with pointer remaining active
- **THEN** the system SHALL keep follow mode OFF until selection is explicitly cleared by Esc.

#### Scenario: Neutral modes
- **WHEN** `dw_esc_mode` is `neutral_last_selection` or `neutral_current_subtitle`
- **THEN** the system SHALL keep follow mode OFF after transition regardless of clear policy.

### Requirement: Neutral Arm Sanitization
The system SHALL reset stale neutral-arm state on transition.

#### Scenario: Transition clears prior neutral arm
- **WHEN** a transition seek is executed from any prior state
- **THEN** the system SHALL set `DW_ESC_NEUTRAL_ARMED=false` before applying post-transition policy.
