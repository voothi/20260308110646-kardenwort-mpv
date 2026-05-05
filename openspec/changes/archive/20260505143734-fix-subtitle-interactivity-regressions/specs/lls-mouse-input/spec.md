# Delta Spec: lls-mouse-input

## Modified Requirements

### Requirement: State-Aware Scroll Synchronization
The mouse input system SHALL ensure that viewport-altering events (scrolling) only synchronize the logical cursor state when an active user-initiated interaction (dragging) is in progress **AND the Drum Window is NOT OFF**.
- **Passive Scroll Stability**: Passive scrolling SHALL NOT update highlight coordinates based on mouse position.
- **Active Drag Sync**: Scrolling while holding a button SHALL continuously update hit-test coordinates.
- **Auto-scroll Guard**: The viewport auto-scroll mechanism SHALL be strictly disabled when `FSM.DRUM_WINDOW == "OFF"`.

#### Scenario: Auto-scroll suppressed in OSD mode
- **WHEN** the Drum Window is `OFF`
- **AND** the user clicks and holds the mouse button on a subtitle at the edge of the screen
- **THEN** the system SHALL NOT increment or decrement the selection cursor index.
- **AND** the selection range SHALL NOT expand beyond the initially clicked word or line.
