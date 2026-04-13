## MODIFIED Requirements

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
The mouse input system SHALL ensure that viewport-altering events (scrolling) only synchronize the logical cursor state when an active user-initiated interaction (dragging) is in progress. Additionally, if a Ctrl-pending set is active, scroll events SHALL discard the set before updating the viewport.

#### Scenario: Drag-Selection Hit-Test Refresh
- **WHEN** a mouse wheel event is processed during an active drag operation
- **THEN** the system SHALL recalculate the hit-test and update the logical cursor to match the new word under the pointer

#### Scenario: Passive Scroll Stability
- **WHEN** a mouse wheel event is processed while NOT dragging
- **THEN** the system SHALL refresh the OSD layout but SHALL NOT update the logical cursor coordinates from the mouse position

## ADDED Requirements

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
