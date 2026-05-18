## MODIFIED Requirements

### Requirement: Seek Synchronization Recovery
The system SHALL resolve follow/manual state after transition seek events according to Esc mode and selection-retention policy.

#### Scenario: Seeking while in Normal Mode (Book Mode OFF)
- **WHEN** the user executes a line transition seek (`Enter` or double-click)
- **THEN** the system SHALL apply the transition policy matrix and maintain consistent viewport behavior with the resulting follow/manual state.

#### Scenario: Seeking while in Book Mode (ON)
- **WHEN** the user executes a line transition seek (`Enter` or double-click)
- **THEN** the system SHALL apply the transition policy matrix without hard-coded Book Mode overrides, using Esc mode and selection-retention policy as the source of truth.

#### Scenario: Manual Seek to Selected Line with retained pointer
- **WHEN** `dw_esc_mode=auto_follow_current` and `dw_clear_selection_after_transition=no`
- **THEN** the system SHALL preserve manual mode while pointer remains active and SHALL restore follow only after pointer clear via Esc.
