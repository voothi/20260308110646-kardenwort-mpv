## Why

This change addresses architectural divergences and logic errors within the FSM (Finite State Machine) system. A recent audit revealed that the FSM specification contained syntax errors and, more critically, the implementation of `get_center_index` had inverted priorities (the "Padding Trap") that broke the "Autopause ON PHRASE" functionality, cutting off audio at the start of subtitle fragments. Hardening these specifications ensures consistent behavior and prevents future regressions in the immersion engine.

## What Changes

- **Spec-Code Synchronization**: Align the `fsm-architecture` specification with the proven "mainline" implementation logic.
- **Diagram Hardening**: Fix Mermaid syntax errors in `state-diagram.md` (e.g., `DR_MODE` typos and nested state redefinitions) to ensure architectural diagrams are renderable and accurate.
- **Priority Codification**: Explicitly define the `get_center_index` evaluation order (Sentinel -> Binary Search -> Overlap Priority) to protect the Jerk-Back mechanism.
- **Loop Prevention Documentation**: Document the `JUST_JERKED_TO` flag mechanism within the FSM state transitions to explain how the system handles phrase-mode overlaps without infinite seek loops.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `fsm-architecture`: Updating requirements to enforce correct padding priority and state transition invariants.

## Impact

- `openspec/specs/fsm-architecture/spec.md`: Updated requirements for index resolution.
- `openspec/specs/fsm-architecture/state-diagram.md`: Fixed Mermaid syntax and updated flow logic.
