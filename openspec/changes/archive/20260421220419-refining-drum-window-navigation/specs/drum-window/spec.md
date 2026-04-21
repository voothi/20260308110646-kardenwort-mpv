## MODIFIED Requirements

### Requirement: Scroll-Aware Selection Continuity
The Drum Window SHALL ensure that any active text selection, word-highlight, or the focus cursor position is preserved and correctly synchronized when the viewport is scrolled or when interacting with different input layouts.

#### Scenario: Wheel Scroll Selection Stability
- **WHEN** the user is actively dragging the mouse to select text (MBTN_LEFT down)
- **AND** the user scrolls the mouse wheel (WHEEL_UP or WHEEL_DOWN)
- **THEN** the system SHALL immediately update the selection range to include the word now under the mouse cursor at its new viewport position.
- **AND** the selection SHALL NOT be cleared or disrupted by the scroll event.

#### Scenario: Visual Cursor Sync (Pointer Jump)
- **WHEN** a mouse-based interaction occurs (e.g., clicking on a word with a pairing modifier)
- **THEN** the system SHALL immediately synchronize the Drum Window cursor (Yellow Highlight) and the anchor point to the word under the mouse pointer.
- **AND** this synchronization SHALL occur before the specific action logic (e.g., toggling) is executed.
- **AND** the sticky horizontal navigation anchor (`FSM.DW_CURSOR_X`) SHALL be reset to ensure the next keyboard movement re-anchors to the new cursor position.
