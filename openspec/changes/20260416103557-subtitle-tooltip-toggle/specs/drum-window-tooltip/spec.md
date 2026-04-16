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

### Requirement: Context-Sensitive Tooltip Targeting
The toggled keyboard tooltip ('e') SHALL prioritize different text elements based on the player's playback state to ensure the most relevant information is displayed.

#### Scenario: Tooltip follows active subtitle during playback
- **GIVEN** the video is currently playing (not paused)
- **WHEN** the keyboard tooltip is toggled ON ('e')
- **THEN** the tooltip SHALL display information for the **currently playing subtitle** (white highlight)
- **AND** it SHALL dynamically update its content and position as the video advances to the next subtitle.

#### Scenario: Tooltip follows selection cursor when paused
- **GIVEN** the video is currently paused
- **WHEN** the keyboard tooltip is toggled ON ('e')
- **THEN** the tooltip SHALL display information for the **manual selection cursor** (yellow pointer).
- **AND** it SHALL dynamically update its content and position if the user moves the cursor (e.g., via arrows or LMB).
