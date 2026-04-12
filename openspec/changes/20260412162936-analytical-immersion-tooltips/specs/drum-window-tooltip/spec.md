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

#### Scenario: Multi-line selection drag
- **WHEN** the user is holding down the Left Mouse Button (LMB) and dragging the pointer across multiple lines
- **THEN** all tooltips SHALL remain suppressed and hidden throughout the duration of the drag

#### Scenario: Sticky suppression on focused line
- **WHEN** the user has suppressed a tooltip on line X using the Left Mouse Button (LMB)
- **AND** the user releases the LMB
- **THEN** the tooltip SHALL remain suppressed for line X
- **AND** the tooltip SHALL only resume display once the user moves the pointer focus to a different line Y
