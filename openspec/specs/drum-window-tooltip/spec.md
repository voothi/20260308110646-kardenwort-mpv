## Purpose

Provides supplemental translation, dictionary, or context information for the currently active or selected subtitle within the Drum Window ('w').
## Requirements
### Requirement: Tooltip Styling Unification
The Tooltip system SHALL support the standard suite of visual parameters (font name, font size, bg opacity, text color, boldness, etc.) following the project's unified schema to ensure stylistic parity with the parent display.

#### Scenario: Stylistic Parity
- **WHEN** the user modifies `tooltip_bg_opacity`, `tooltip_font_size`, or `tooltip_font_name`
- **THEN** the tooltip rendering engine SHALL apply these values to the OSD overlay using standardized ASS tags, matching the visual weight and typography of the Drum Window and Drum Mode.

#### Scenario: Unified Boldness
- **WHEN** the `tooltip_font_bold` option is toggled
- **THEN** the tooltip text SHALL render with the corresponding boldness state, synchronized with the user's preference for the active display mode.

### Requirement: Keyboard Tooltip Toggling
The system SHALL provide configurable keyboard shortcuts (defined in `mpv.conf`) to toggle the visibility of the tooltip for the currently active subtitle. This functionality SHALL be restricted entirely to the Drum Window ('w') mode.

#### Scenario: Toggling the tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key (e.g., 'e' or 'у') while the Drum Window ('w') is active and the tooltip is hidden
- **THEN** the tooltip for the active subtitle SHALL appear on the screen

#### Scenario: Hiding a visible tooltip with 'e' key
- **WHEN** the user presses the assigned toggle key while the Drum Window tooltip is currently visible (forced state)
- **THEN** the tooltip SHALL be hidden, regardless of whether the target subtitle line has changed since it was first displayed.

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

#### Scenario: Tooltip targets active subtitle on seek while paused
- **GIVEN** the video is currently paused
- **AND** the keyboard tooltip is toggled ON ('e')
- **WHEN** the user seeks to a different subtitle (e.g., via 'a' or 'd')
- **THEN** the tooltip SHALL switch to follow the **active subtitle** (white highlight) at its new position.

#### Scenario: Tooltip targets selection cursor on cursor move
- **GIVEN** the video is currently paused
- **AND** the keyboard tooltip is toggled ON ('e')
- **WHEN** the user moves the manual selection cursor (e.g., via arrows or LMB)
- **THEN** the tooltip SHALL switch to follow the **selection cursor** (yellow pointer).

#### Scenario: Tooltip suppressed when target is off-screen
- **GIVEN** the target subtitle (active or cursor) is currently scrolled off-screen
- **WHEN** the user toggles the keyboard tooltip ON ('e')
- **THEN** the tooltip SHALL NOT appear on screen
- **BUT** the system SHALL remember the forced state, so it appears automatically once the target line scrolls back into view.

### Requirement: RMB Interaction Preservation
The system SHALL preserve legacy Right Mouse Button (RMB) interaction patterns for tooltips.

#### Scenario: Tooltip remains visible and follows focus while RMB is held
- **GIVEN** the Drum Window tooltip is configured for `CLICK` mode
- **WHEN** the user presses and holds RMB and moves the mouse across multiple subtitle lines
- **THEN** the tooltip SHALL dynamically update to show information for the line currently under the mouse pointer.

#### Scenario: Tooltip dismisses when mouse focus leaves pinned line (CLICK Mode)
- **GIVEN** the Drum Window tooltip is in `CLICK` mode (no active keyboard force)
- **WHEN** the user right-clicks a line to pin the tooltip
- **AND** the user then moves the mouse focus to a different subtitle line
- **THEN** the pinned tooltip SHALL be dismissed.

