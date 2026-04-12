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
The system SHALL dismiss the tooltip instantly when the context changes.

#### Scenario: Pointer deviates from pinned line
- **WHEN** the tooltip is currently pinned to line X
- **AND** the user moves the pointer such that hit testing resolves to line Y or null
- **THEN** the tooltip SHALL be immediately dismissed and hidden from screen

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
