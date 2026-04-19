## ADDED Requirements

### Requirement: Interaction Isolation (Action vs. Selection)
The mouse interaction engine SHALL strictly isolate informational actions from state-changing selection actions.

#### Scenario: RMB Pinned Tooltip
- **WHEN** the user clicks RMB (Action: Tooltip Pin)
- **THEN** it SHALL NOT update the logical `DW_CURSOR_LINE/WORD` or `DW_ANCHOR_LINE/WORD`.
- **AND** the existing yellow selection cursor SHALL remain at its previous location.

#### Scenario: Selection Dragging Exclusion
- **GIVEN** a mouse interaction is flagged as `updates_selection = false` (e.g., RMB Pin, Tooltip Toggle).
- **WHEN** the user presses and holds the button and moves the mouse.
- **THEN** the system SHALL NOT enter the `DRAGGING` state and SHALL NOT update the selection range.

### Requirement: Global Interaction Hardening (Mouse Shield)
To support remote control and unstable hardware environments, the system SHALL implement a temporal suppression layer for mouse events.

#### Scenario: Keyboard Navigation Ghost Suppression
- **WHEN** the user executes any navigation command (Arrows, Enter, a/d, Seek, etc.).
- **THEN** the system SHALL set a temporal lock `FSM.DW_MOUSE_LOCK_UNTIL = current_time + 150ms`.
- **AND** all incoming mouse events (down/up/move/scroll) SHALL be discarded while the lock is active.

#### Scenario: Modifier-Exempt Responsiveness
- **WHEN** the user presses a standalone modifier key (Ctrl, Shift, Alt, Meta).
- **THEN** the system SHALL NOT trigger the 150ms mouse lock.
- **AND** mouse + keyboard combinations (e.g., Ctrl+Click) SHALL remain fully responsive.

### Requirement: Stream-Agnostic Initialization
Drum Window activation SHALL support internal and embedded subtitle streams that lack local file paths.

#### Scenario: Embedded Subtitle Support
- **WHEN** the user attempts to open the Drum Window (`w`).
- **AND** no external subtitle file path is detected (`pri.path` is nil).
- **BUT** subtitle segments are currently loaded in the engine's memory (`#pri.subs > 0`).
- **THEN** the system SHALL proceed with opening and rendering the Drum Window.
