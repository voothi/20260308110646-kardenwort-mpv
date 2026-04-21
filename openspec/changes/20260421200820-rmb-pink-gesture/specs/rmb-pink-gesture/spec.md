## ADDED Requirements

### Requirement: RMB+LMB Simultaneous Pink Gesture
The system SHALL support a two-button mouse gesture for committing a yellow drag-selection as a pink (Ctrl-path) highlight, eliminating the need for any keyboard input in mouse-only workflows.

**Gesture definition**: The user presses and holds LMB to initiate a drag-selection. While LMB remains held, the user presses RMB. On release of either button (while the other is still held), the current yellow selection SHALL be committed as pink via `cmd_dw_toggle_pink`.

#### Scenario: LMB up while RMB held triggers pink
- **WHEN** the user drags a selection with LMB held
- **AND** presses RMB while LMB is still held
- **AND** releases LMB while RMB remains down
- **THEN** the system SHALL call `cmd_dw_toggle_pink` on the current selection
- **AND** the yellow selection SHALL be cleared and the words committed to `DW_CTRL_PENDING_SET`

#### Scenario: RMB up while LMB held triggers pink
- **WHEN** the user drags a selection with LMB held
- **AND** presses RMB while LMB is still held
- **AND** releases RMB while LMB remains down
- **THEN** the system SHALL call `cmd_dw_toggle_pink` on the current selection symmetrically

#### Scenario: Simultaneous release triggers pink exactly once
- **WHEN** both LMB and RMB are released within 50 ms of each other
- **THEN** the pink gesture SHALL fire exactly once (the first `up` event wins)
- **AND** the second `up` event SHALL be a no-op (debounced by `DW_RMB_GESTURE_LAST_TIME`)

### Requirement: Physical Button State Tracking
The FSM SHALL maintain independent boolean flags for the physical press state of LMB and RMB, decoupled from the drag-selection state machine.

- `DW_LMB_DOWN`: Set to `true` on LMB "down", `false` on LMB "up".
- `DW_RMB_DOWN`: Set to `true` on RMB "down", `false` on RMB "up".
- `DW_RMB_GESTURE_LAST_TIME`: Timestamp (seconds) of the last pink gesture commit; initialized to `0`.

#### Scenario: Flags reset on Drum Window close
- **WHEN** the Drum Window is deactivated (`manage_dw_bindings(false)`)
- **THEN** `DW_LMB_DOWN`, `DW_RMB_DOWN`, and `DW_RMB_GESTURE_LAST_TIME` SHALL be reset to their initial values before bindings are removed.

### Requirement: Tooltip Suppression During LMB-Hold Gesture
The tooltip-pin action SHALL be suppressed when RMB is pressed while LMB is physically held, to prevent the tooltip overlay from interfering with the pink-gesture workflow.

#### Scenario: RMB down while LMB held suppresses tooltip
- **WHEN** LMB is held (drag in progress, `DW_LMB_DOWN == true`)
- **AND** the user presses RMB
- **THEN** the system SHALL set `DW_RMB_DOWN = true`
- **AND** SHALL NOT open the tooltip
- **AND** SHALL early-return from the tooltip-pin handler

#### Scenario: RMB alone still opens tooltip
- **WHEN** LMB is NOT held (`DW_LMB_DOWN == false`)
- **AND** the user presses RMB
- **THEN** the system SHALL proceed with normal tooltip-pin behavior (unchanged)
