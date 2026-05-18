## ADDED Requirements

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
