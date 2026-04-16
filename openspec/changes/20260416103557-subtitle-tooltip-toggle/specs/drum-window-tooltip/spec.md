## ADDED Requirements

### Requirement: Keyboard Tooltip Toggling
The system SHALL provide configurable keyboard shortcuts (defined in `mpv.conf`) to toggle the visibility of the tooltip for the currently active subtitle. This functionality SHALL be restricted entirely to the Drum Window ('w') mode.

#### Scenario: Toggling the tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key (e.g., 'e' or 'у') while the Drum Window ('w') is active and the tooltip is hidden
- **THEN** the tooltip for the active subtitle SHALL appear on the screen

#### Scenario: Hiding a visible tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key while the Drum Window tooltip is currently visible
- **THEN** the tooltip SHALL be hidden

### Requirement: Dynamic Tooltip Positioning
When a tooltip is visible (toggled via keyboard or pinned via mouse), it SHALL dynamically update its vertical (OSD Y) position to remain centered relative to its associated subtitle line as the line moves during scrolling.

#### Scenario: Tooltip follows scrolling text
- **WHEN** a translation tooltip is visible for a specific subtitle line
- **AND** the user scrolls the Drum Window (e.g., via wheel, arrow keys, or playback)
- **THEN** the tooltip SHALL move vertically on the screen, maintaining its alignment with the horizontal centerline of the target subtitle line.
