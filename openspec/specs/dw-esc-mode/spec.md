# DW Esc Mode

## Purpose
Defines and manages the escape behavior within the Drum Window navigation system, allowing users to choose how the focus/state is handled upon exit/escape.
## Requirements
### Requirement: DW Esc Mode Cycling
The system SHALL provide a mechanism to cycle through different escape behaviors in the Drum Window.

#### Scenario: Cyclic Mode Transition
- **WHEN** the user triggers the `dw-cycle-esc-mode` command (default key: `n` / `т`)
- **THEN** the system SHALL transition to the next mode in the sequence: `auto_follow_current` -> `neutral_last_selection` -> `neutral_current_subtitle` -> `auto_follow_current`.

### Requirement: Professional OSD Feedback
The system SHALL display a clear OSD message indicating the newly selected mode using standardized labels.

#### Scenario: OSD Label Verification
- **WHEN** the mode transitions to `auto_follow_current`
- **THEN** the OSD SHALL display: `DW Esc Mode: AUTO FOLLOW CURRENT`

#### Scenario: OSD Label Verification (Neutral Last Selection)
- **WHEN** the mode transitions to `neutral_last_selection`
- **THEN** the OSD SHALL display: `DW Esc Mode: NEUTRAL LAST SELECTION`

#### Scenario: OSD Label Verification (Neutral Current Subtitle)
- **WHEN** the mode transitions to `neutral_current_subtitle`
- **THEN** the OSD SHALL display: `DW Esc Mode: NEUTRAL CURRENT SUBTITLE`

### Requirement: Omnidirectional Verification
The feature SHALL be verified across different keyboard layouts and navigation states.

#### Scenario: Cyrillic Key Support
- **WHEN** the user presses `т` (Cyrillic equivalent of `n`)
- **THEN** the mode SHALL cycle identically to the `n` key.

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

