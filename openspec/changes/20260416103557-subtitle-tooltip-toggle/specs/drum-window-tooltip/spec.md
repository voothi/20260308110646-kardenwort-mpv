## ADDED Requirements

### Requirement: Keyboard Tooltip Toggling
The system SHALL provide configurable keyboard shortcuts (defined in `mpv.conf`) to toggle the visibility of the tooltip for the currently active subtitle. This functionality SHALL be restricted entirely to the Drum Window ('w') mode.

#### Scenario: Toggling the tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key (e.g., 'e' or 'у') while the Drum Window ('w') is active and the tooltip is hidden
- **THEN** the tooltip for the active subtitle SHALL appear on the screen

#### Scenario: Hiding a visible tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key while the Drum Window tooltip is currently visible
- **THEN** the tooltip SHALL be hidden
