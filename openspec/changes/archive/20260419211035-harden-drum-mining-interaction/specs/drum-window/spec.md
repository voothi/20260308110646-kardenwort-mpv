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

## ADDED Requirements

### Requirement: Multi-Input Pairing Persistence
The Drum Window SHALL maintain a persistent "Paired Selection" set (indicated by Pink highlight) that persists across multiple interaction events and is independent of the standard Yellow selection range.

#### Scenario: Persistence Across Modifier Release
- **WHEN** words are added to the paired selection set while holding a modifier key (e.g., Ctrl)
- **AND** the user releases the modifier key
- **THEN** the paired selection set (Pink highlights) SHALL NOT be cleared.

#### Scenario: Explicit Paired Set Discard
- **WHEN** the user triggers the explicit discard command (e.g., Ctrl+ESC)
- **THEN** the entire pending paired selection set SHALL be cleared immediately.

### Requirement: Range-Aware Paired Selection
The Drum Window SHALL allow a contiguous yellow selection range to be converted into a discrete paired selection set in a single action.

#### Scenario: Drag-to-Pair (Mouse)
- **WHEN** the user drags a selection using a mouse-based pairing shortcut (e.g., Ctrl+MBTN_LEFT)
- **THEN** the system SHALL render a standard yellow selection range during the drag.
- **AND** upon release, the system SHALL convert every word in that range into the pink paired selection set and clear the temporary yellow selection.

#### Scenario: Select-then-Toggle (Keyboard)
- **WHEN** a yellow selection range is active
- **AND** the user triggers the pairing toggle command (e.g., `t`)
- **THEN** the system SHALL convert the entire yellow range into the pink paired selection set.
