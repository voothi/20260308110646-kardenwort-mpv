## MODIFIED Requirements

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
