## MODIFIED Requirements

### Requirement: Scroll-Aware Selection Continuity
The Drum Window SHALL ensure that any active text selection or word-highlight state is preserved and correctly synchronized when the viewport is scrolled using the mouse wheel.

#### Scenario: Wheel Scroll Selection Stability
- **WHEN** the user is actively dragging the mouse to select text (MBTN_LEFT down)
- **AND** the user scrolls the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL immediately update the selection range to include the word now under the mouse cursor at its new viewport position.
- **AND** the selection SHAL NOT be cleared or disrupted by the scroll event.

#### Scenario: Highlight-to-Mouse Synchronization
- **WHEN** the Drum Window is active and the user scrolls the mouse wheel
- **THEN** the system SHALL maintain the highlight on the word currently under the mouse cursor.
- **AND** the cursor state (`FSM.DW_CURSOR_WORD`) SHALL NOT be reset to an invalid state.
