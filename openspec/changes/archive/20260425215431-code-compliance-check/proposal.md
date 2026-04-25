## Why

The Kardenwort-mpv project has a rich set of specifications in `openspec\specs` that define its core behaviors. To ensure long-term stability and functional integrity, it is necessary to perform a comprehensive audit to verify that the current implementation meets all documented requirements.

## What Changes

- **Code Compliance Audit**: A systematic review of all active specifications against the codebase.
- **Gap Identification**: Explicitly documenting any areas where the code deviates from or fails to implement specification requirements.
- **Compliance Status Report**: Generating a consolidated view of the project's adherence to its own standards.

## Capabilities

### New Capabilities
- `spec-compliance-audit`: A systematic framework for verifying implementation against the `openspec\specs` registry.

### Modified Capabilities
<!-- No existing requirements are changing; this is an audit of current state. -->

## Impact

- **Audit only**: This change does not modify application logic directly.
- **Discovery**: May surface necessary bug fixes or implementation tasks which will be tracked in subsequent changes if needed.
