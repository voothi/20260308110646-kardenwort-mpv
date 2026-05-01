## ADDED Requirements

### Requirement: Interactive Translation Tooltip
The Drum Window translation tooltip (E) SHALL support word-level mouse interaction, allowing users to select or move the focus cursor directly from the secondary subtitle display.

#### Scenario: Tooltip Word Selection
- **GIVEN** the translation tooltip is visible in Window Mode (W)
- **WHEN** the user clicks on a word in the tooltip
- **THEN** the system SHALL update the global focus cursor (`FSM.DW_CURSOR_WORD`) to match the clicked word's logical index.
- **AND** the primary Drum Window SHALL immediately update its highlight position to reflect the new selection.
- **AND** the system SHALL NOT blink or dismiss the tooltip during a valid internal word selection.

### Requirement: Surgical Interaction (Gap Pass-Through)
The translation tooltip SHALL follow a "Surgical" interaction model, where mouse hits are only registered on actual text elements.
- **GIVEN** the tooltip is visible
- **WHEN** the user clicks on a transparent "gap" between words or lines in the tooltip
- **THEN** the click SHALL pass through to the underlying Drum Window elements.

### Requirement: Sticky Quick-View Stability
When the user is "Quick-Viewing" (holding RMB to hover over translations), the tooltip SHALL exhibit "sticky" behavior to prevent flickering in high-precision vertical movement.
- **GIVEN** the user is holding the right mouse button (RMB) in Window Mode
- **WHEN** the mouse moves through gaps or non-interactive areas between subtitle lines
- **THEN** the system SHALL maintain the last valid tooltip content until a new valid subtitle line is hit.
- **AND** the tooltip OSD SHALL NOT be cleared or update its content to empty during this transition.

#### Scenario: Tooltip Persistent Selection
- **GIVEN** the translation tooltip is visible
- **WHEN** the user Ctrl+Clicks a word in the tooltip
- **THEN** that word SHALL be added to the persistent paired selection set (Pink).
- **AND** the primary Drum Window SHALL show the corresponding primary word as part of the paired set.

#### Scenario: Hit Zone Parity
- **WHEN** the tooltip is rendered or updated
- **THEN** the system SHALL calculate and store bounding box metadata (Hit Zones) for every word in the tooltip.
- **AND** these zones SHALL be correctly mapped to the screen coordinates of the tooltip's right-aligned (`an6`) layout.
