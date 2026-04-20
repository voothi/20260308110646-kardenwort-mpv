## DEPRECATED Requirements

### Requirement: Ctrl-Set Discard on Modifier Release
The requirement to automatically discard selection accumulators on `Ctrl` key release is **REMOVED** to support persistent curation on minimalist remotes.

## ADDED Requirements

### Requirement: Global Interaction Shield (Hardware Jitter Filter)
The system SHALL implement a **150ms** suppression window following any keyboard or remote navigation command.
- **Behavior**: All mouse button/scroll signals SHALL be ignored while the lock is active to filter hardware-level ghost clicks.

### Requirement: Pointer Jump Sync
The system SHALL synchronize the logical focus (hit-test) to the exact coordinate under the pointer *immediately prior* to dispatching any mouse action.
- **Rationale**: Prevents actions from being applied to stale coordinates during rapid pointer movement or hardware latency.
