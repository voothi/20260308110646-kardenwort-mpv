## DEPRECATED Requirements

### Requirement: Ctrl-Set Discard on Modifier Release
The requirement to discard the `ctrl_pending_set` upon release of the `Ctrl` key is **REMOVED** to support minimalist input devices.

## ADDED Requirements

### Requirement: Global Interaction Shield
The system SHALL implement a 150ms temporal suppression window to filter hardware-level ghost clicks during rapid navigation.

#### Scenario: Navigation Shield Activation
- **WHEN** a keyboard or remote navigation command (e.g., Seek, Add, Pair) is executed
- **THEN** the system SHALL ignore all incoming mouse button signals for the next **150ms**.

### Requirement: Coordinate-Precise Sync
The system SHALL ensure the focus cursor and selection anchor are updated to the exact coordinate under the pointer immediately prior to action dispatch.

#### Scenario: Pointer Jump Sync
- **WHEN** any mouse-based action is triggered
- **THEN** the system SHALL synchronize the virtual focus to the physical coordinate under the pointer.
- **AND** this sync SHALL occur before the action's logic is processed.
