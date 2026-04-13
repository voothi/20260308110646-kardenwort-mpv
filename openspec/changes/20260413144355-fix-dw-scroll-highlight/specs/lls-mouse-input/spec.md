## MODIFIED Requirements

### Requirement: State-Aware Scroll Synchronization
The mouse input system SHALL ensure that viewport-altering events (scrolling) only synchronize the logical cursor state when an active user-initiated interaction (dragging) is in progress.

#### Scenario: Drag-Selection Hit-Test Refresh
- **WHEN** a mouse wheel event is processed during an active drag operation
- **THEN** the system SHALL recalculate the hit-test and update the logical cursor to match the new word under the pointer.

#### Scenario: Passive Scroll Stability
- **WHEN** a mouse wheel event is processed while NOT dragging
- **THEN** the system SHALL refresh the OSD layout but SHALL NOT update the logical cursor coordinates from the mouse position.
