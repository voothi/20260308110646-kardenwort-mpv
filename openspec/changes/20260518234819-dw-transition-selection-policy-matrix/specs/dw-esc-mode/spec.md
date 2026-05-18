## MODIFIED Requirements

### Requirement: Omnidirectional Verification
The feature SHALL be verified across keyboard layouts, navigation states, and post-transition selection policies.

#### Scenario: Cyrillic Key Support
- **WHEN** the user presses `т` (Cyrillic equivalent of `n`)
- **THEN** the mode SHALL cycle identically to the `n` key.

#### Scenario: Transition neutral-arm reset
- **WHEN** any transition seek (`Enter` or double-click) is executed under any Esc mode
- **THEN** `DW_ESC_NEUTRAL_ARMED` SHALL be reset to false immediately after transition.

#### Scenario: Auto-follow mode transition with pointer retained
- **WHEN** `dw_esc_mode=auto_follow_current` and transition runs with `dw_clear_selection_after_transition=no`
- **THEN** follow SHALL remain OFF while pointer remains active and SHALL only restore after Esc clears the pointer.

#### Scenario: Neutral mode transition behavior
- **WHEN** `dw_esc_mode` is `neutral_last_selection` or `neutral_current_subtitle` after transition seek
- **THEN** follow SHALL remain OFF and neutral re-arming SHALL be governed by subsequent Esc interaction, not inherited transition state.
