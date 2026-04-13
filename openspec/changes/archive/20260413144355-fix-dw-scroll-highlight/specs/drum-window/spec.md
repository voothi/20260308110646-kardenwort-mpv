## MODIFIED Requirements

### Requirement: Scroll-Aware Selection Continuity
The Drum Window SHALL ensure that any active text selection or word-highlight state is preserved and correctly synchronized when the viewport is scrolled using the mouse wheel.

#### Scenario: Wheel Scroll Selection Stability
- **WHEN** the user is actively dragging the mouse to select text (MBTN_LEFT down)
- **AND** the user scrolls the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL immediately update the selection range to include the word now under the mouse cursor at its new viewport position.
- **AND** the selection SHALL NOT be cleared or disrupted by the scroll event.

#### Scenario: Stationary Active Highlight
- **WHEN** the Drum Window is scrolled via mouse wheel while NOT dragging
- **THEN** the system SHALL maintain the highlight on the specific text index previously selected.
- **AND** the highlight SHALL NOT snap to the word currently under the mouse pointer.
- **AND** the cursor state (`FSM.DW_CURSOR_WORD`) SHALL NOT be reset to an invalid state.
