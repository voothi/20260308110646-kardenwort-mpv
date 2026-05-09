## MODIFIED Requirements

### Requirement: Keyboard Tooltip Toggling
The system SHALL provide configurable keyboard shortcuts (defined in `mpv.conf`) to toggle the visibility of the tooltip for the currently active subtitle. This functionality SHALL be available in Drum Window mode, Drum Mode, and SRT mode (when using custom OSD rendering).

#### Scenario: Toggling the tooltip in SRT mode
- **WHEN** the user presses the assigned toggle key (e.g., 'e') while in SRT mode (Drum Mode OFF, Drum Window OFF)
- **THEN** the translation tooltip for the active subtitle SHALL appear on the screen.

#### Scenario: Toggling the tooltip in Drum Mode
- **WHEN** the user presses the assigned toggle key (e.g., 'e') while Drum Mode is ON
- **THEN** the translation tooltip for the active subtitle SHALL appear on the screen.

### Requirement: Tooltip Interaction Eligibility
The tooltip system SHALL be eligible for activation whenever the primary subtitle is being rendered via the Kardenwort custom OSD (Drum Mode or SRT with custom styling), provided that `osd_interactivity` is enabled.

#### Scenario: Eligibility in Styled SRT Mode
- **GIVEN** `srt_font_size` is greater than 0
- **AND** `osd_interactivity` is true
- **WHEN** the user hovers over a subtitle line in SRT mode
- **THEN** the tooltip SHALL be eligible for display.
