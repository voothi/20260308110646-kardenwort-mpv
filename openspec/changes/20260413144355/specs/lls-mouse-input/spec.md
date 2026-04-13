## MODIFIED Requirements

### Requirement: Unified Mouse Interaction Event Loop
The mouse input system SHALL ensure that all viewport-altering events (scrolling, clicking, dragging) trigger a recalculation of the hit-test mapping when the Drum Window is active.

#### Scenario: Post-Scroll Hit-Test Refresh
- **WHEN** a mouse wheel event is processed in Drum Window mode
- **THEN** the system SHALL invoke a hit-test refresh to synchronize the logical cursor state with the updated ASS layout immediately.
