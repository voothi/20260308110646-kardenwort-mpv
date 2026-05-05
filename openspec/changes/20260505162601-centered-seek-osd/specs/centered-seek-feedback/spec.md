## ADDED Requirements

### Requirement: Centered Seek OSD
The system SHALL display a large, centered OSD message indicating the seek direction and amount when performing a relative time seek via script bindings.

#### Scenario: Forward seek visual feedback
- **WHEN** the user executes `lls-seek_time_forward`
- **THEN** a centered OSD message SHALL appear showing `+<delta>` (e.g., `+2`).

#### Scenario: Backward seek visual feedback
- **WHEN** the user executes `lls-seek_time_backward`
- **THEN** a centered OSD message SHALL appear showing `-<delta>` (e.g., `-2`).

### Requirement: Configurable Seek Amount
The system SHALL allow the user to define the relative seek amount in seconds via the `seek_time_delta` option.

#### Scenario: Adjusting seek amount
- **WHEN** the user sets `lls-seek_time_delta=5` in `mpv.conf`
- **THEN** the `lls-seek_time_forward` command SHALL seek forward by 5 seconds and display `+5`.
