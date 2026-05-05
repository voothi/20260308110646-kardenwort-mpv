## ADDED Requirements

### Requirement: Centered Seek OSD
The system SHALL display a large, centered OSD message indicating the seek direction and amount when performing a relative time seek via script bindings.

#### Scenario: Forward seek visual feedback
- **WHEN** the user executes `lls-seek_time_forward`
- **THEN** a centered OSD message SHALL appear showing `+<delta>` (e.g., `+2`).

#### Scenario: Backward seek visual feedback
- **WHEN** the user executes `lls-seek_time_backward`
- **THEN** a directional OSD message SHALL appear on the left showing `-<delta>`.

### Requirement: Cumulative Seek Accumulator
The system SHALL track and display the total seek amount in parentheses when multiple relative seeks occur within the `seek_osd_duration` window.

#### Scenario: Cumulative seeking
- **WHEN** the user presses `RIGHT` (+2) twice within the OSD window
- **THEN** the second OSD message SHALL show `+2 (+4)`.

### Requirement: Configurable Seek Amount
The system SHALL allow the user to define the relative seek amount in seconds via the `seek_time_delta` option.

#### Scenario: Adjusting seek amount
- **WHEN** the user sets `lls-seek_time_delta=5` in `mpv.conf`
- **THEN** the `lls-seek_time_forward` command SHALL seek forward by 5 seconds and display `+5`.
