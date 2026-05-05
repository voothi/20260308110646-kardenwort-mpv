## ADDED Requirements

### Requirement: Directional Seek OSD
The system SHALL display a directional OSD message indicating the seek direction and amount.
- **Backward**: Displayed on the middle-left (`{\an4}`).
- **Forward**: Displayed on the middle-right (`{\an6}`).

#### Scenario: Forward seek visual feedback
- **WHEN** the user executes `lls-seek_time_forward`
- **THEN** a directional OSD message SHALL appear on the right showing the seek amount.

#### Scenario: Backward seek visual feedback
- **WHEN** the user executes `lls-seek_time_backward`
- **THEN** a directional OSD message SHALL appear on the left showing the seek amount.

### Requirement: YouTube-Style Cumulative Accumulator
The system SHALL track and display the total seek amount for the current session when multiple relative seeks occur in the same direction within the OSD window.
- **Reset**: The accumulator MUST reset if the seek direction changes.

#### Scenario: Cumulative seeking
- **WHEN** the user presses `RIGHT` (+2) twice within the OSD window
- **THEN** the second OSD message SHALL show `+4` (the cumulative total).

### Requirement: Configurable Seek Formatting
The system SHALL allow the user to define message templates for single and cumulative seeks.

#### Scenario: Customizing OSD format
- **WHEN** the user sets `lls-seek_msg_cumulative_format=%P%Vs`
- **THEN** the cumulative message SHALL show with a trailing 's' (e.g., `+4s`).

### Requirement: Granular Seek Styling
The system SHALL provide independent styling parameters (font, size, color, opacity, etc.) for the seek OSD, consistent with other immersion modes.
- **Resolution**: All seek OSD rendering MUST be relative to `Options.font_base_height` to ensure consistent scaling.
