## ADDED Requirements

### Requirement: Tooltip Activation
The system SHALL display a translation tooltip containing secondary subtitles near the hovered primary subtitle line.

#### Scenario: User clicks right mouse button
- **WHEN** the user is holding the pointer over a valid subtitle in drum window mode
- **AND** the user clicks the right mouse button (RMB)
- **THEN** the translation tooltip SHALL aggressively pin to the current line index and display on screen

#### Scenario: Phase 2 Hover Mode is enabled
- **WHEN** the `dw_tooltip_mode` configuration is set to HOVER
- **AND** the user moves the pointer over a valid subtitle line
- **THEN** the translation tooltip SHALL aggressively pin automatically without clicking

### Requirement: Tooltip Dismissal
The system SHALL dismiss the tooltip instantly when the context changes or the user initiates an action.

#### Scenario: Pointer deviates from pinned line
- **WHEN** the tooltip is currently pinned to line X
- **AND** the user moves the pointer such that hit testing resolves to line Y or null
- **THEN** the tooltip SHALL be immediately dismissed and hidden from screen

#### Scenario: User clicks left mouse button
- **WHEN** a translation tooltip is currently visible (either pinned or hovered)
- **AND** the user presses the Left Mouse Button (LMB)
- **THEN** the tooltip SHALL be immediately suppressed and hidden from the screen

#### Scenario: User holds left mouse button
- **WHEN** the user is holding down the Left Mouse Button (LMB)
- **THEN** the translation tooltip SHALL remain suppressed and hidden from the screen for the entire duration of the hold

#### Scenario: User clicks middle mouse button
- **WHEN** a translation tooltip is currently visible (either pinned or hovered)
- **AND** the user presses the Middle Mouse Button (MMB / Wheel Click)
- **THEN** the tooltip SHALL be immediately suppressed and hidden from the screen

#### Scenario: Multi-line selection drag
- **WHEN** the user is holding down the Left Mouse Button (LMB) and dragging the pointer across multiple lines
- **THEN** all tooltips SHALL remain suppressed and hidden throughout the duration of the drag

#### Scenario: Sticky suppression on focused line
- **WHEN** the user has suppressed a tooltip using the Left Mouse Button (LMB)
- **AND** the user releases the LMB
- **THEN** the tooltip SHALL remain suppressed for the line where the interaction ended (Focus X)
- **AND** the tooltip SHALL only resume display once the user moves the pointer focus to a different line Y

#### Scenario: Selection Range Suppression
- **WHEN** Hover Mode (`n`) is ENABLED
- **AND** the user has a red-selection range active (from Line X to Line Y)
- **AND** the user hovers over any line Z where X <= Z <= Y
- **THEN** the translation tooltip SHALL NOT automatically pop up
- **AND** the tooltip SHALL only appear if the user explicitly clicks the Right Mouse Button (RMB)

### Requirement: Tooltip Positioning and Wrapping
The tooltip SHALL not overflow standard width or overlap the drum window destructively.

#### Scenario: Rendering translation box
- **WHEN** the tooltip is generated
- **THEN** the system SHALL anchor it near the right screen edge `{\an6}`
- **AND** the system SHALL enforce character width/wrapping constraints to limit infinite horizontal expansion
- **AND** the system SHALL apply a semi-transparent background to allow overlap blending

### Requirement: Subtitle Context Fetching
The tooltip SHALL fetch translations based chronologically on the primary subtitle text.

#### Scenario: Fetching contextual lines
- **WHEN** the tooltip is drawing for primary line X
- **THEN** it SHALL resolve the temporal window of line X
- **AND** it SHALL query `Tracks.sec` traversing chronologically `dw_tooltip_context_lines` forward and backward to render full translation sentences.
