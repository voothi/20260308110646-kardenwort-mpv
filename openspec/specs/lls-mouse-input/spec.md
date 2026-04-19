## ADDED Requirements

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

### Requirement: Mouse Motion Tracking
The system SHALL continuously track and evaluate the mouse position during Drum Window Mode.

#### Scenario: Pointer deviates from pinned line
- **WHEN** the user is dragging or simply moving the mouse without dragging
- **AND** the tooltip window layer relies on hover dynamics
- **THEN** the system SHALL actively supply `hit_test` events to the tooltip manager

### Requirement: RMB Interaction
The system SHALL bind `MBTN_RIGHT` dynamically when Drum Window mode activates.

#### Scenario: Tooltip Click Trigger
- **WHEN** in Drum Window Mode
- **THEN** `MBTN_RIGHT` SHALL dispatch drawing instructions to pin the tooltip 
- **AND** this explicit binding SHALL automatically deactivate when Window mode drops

### Requirement: Hover Mode Toggle
The system SHALL support a configurable hotkey to toggle Phase 2 "Hover Mode".

#### Scenario: User toggles Hover Mode using configured key
- **WHEN** the user is in Drum Window Mode
- **AND** the user presses the `dw_tooltip_hover_key` (e.g. `n`) mapped in configuration
- **THEN** the system SHALL swap `FSM.DW_TOOLTIP_MODE` between "CLICK" and "HOVER"
### Requirement: State-Aware Scroll Synchronization
The mouse input system SHALL ensure that viewport-altering events (scrolling) only synchronize the logical cursor state when an active user-initiated interaction (dragging) is in progress.

#### Scenario: Drag-Selection Hit-Test Refresh
- **WHEN** a mouse wheel event is processed during an active drag operation
- **THEN** the system SHALL recalculate the hit-test and update the logical cursor to match the new word under the pointer.

#### Scenario: Passive Scroll Stability
- **WHEN** a mouse wheel event is processed while NOT dragging
- **THEN** the system SHALL refresh the OSD layout but SHALL NOT update the logical cursor coordinates from the mouse position.

### Requirement: Ctrl Modifier Key State Tracking
The mouse input system SHALL track the held/released state of the Ctrl key while the Drum Window is active, exposing a `ctrl_held` boolean for use by gesture dispatchers.

#### Scenario: Ctrl key state set on press
- **WHEN** the Drum Window is active
- **AND** the user presses the Ctrl key
- **THEN** the system SHALL set `ctrl_held = true`

#### Scenario: Ctrl key state cleared on release
- **WHEN** the Drum Window is active
- **AND** the user releases the Ctrl key
- **THEN** the system SHALL set `ctrl_held = false`
- **AND** the system SHALL emit a `ctrl-released` event to trigger accumulator discard

### Requirement: Ctrl+LMB Gesture Routing
When `ctrl_held` is true, LMB press events SHALL be routed to the Ctrl-accumulator handler instead of the drag-selection handler.

#### Scenario: LMB with Ctrl held routes to accumulator
- **WHEN** the user presses LMB while `ctrl_held` is true
- **THEN** the word under the cursor SHALL be passed to the `ctrl_pending_set` toggle handler
- **AND** the drag-selection state machine SHALL NOT be entered

#### Scenario: LMB without Ctrl routes to drag as before
- **WHEN** the user presses LMB while `ctrl_held` is false
- **THEN** the existing drag-selection behavior SHALL remain unchanged

### Requirement: Ctrl+MMB Gesture Routing
When `ctrl_held` is true, MMB press events SHALL be routed to the Ctrl-accumulator commit handler.

#### Scenario: MMB with Ctrl held routes to commit handler
- **WHEN** the user presses MMB while `ctrl_held` is true
- **THEN** the system SHALL pass the event to the `ctrl-multiselect` commit handler
- **AND** the word under the cursor SHALL be evaluated for set membership before dispatching export

#### Scenario: MMB without Ctrl routes to standard export as before
- **WHEN** the user presses MMB while `ctrl_held` is false
- **THEN** the existing MMB export/drag behavior SHALL remain unchanged
