## Why

This change formalizes the Regression Audit & Release Documentation introduced in Release v1.2.20. Following the high-intensity development of the Advanced Mouse Selection feature set (v1.2.18), it was critical to perform a formal audit to ensure zero regressions in the core FSM logic. This release serves as the "packaging" phase, ensuring that the project's documentation, release notes, and README accurately reflect the latest feature drop.

## What Changes

- Formal **Regression Audit**: A hunk-by-hunk verification of the 18 commits between `abf23f4` and `27c1e76`, confirming that all changes to `lls_core.lua` are either additive or precisely scoped refactors.
- **Documentation Packaging**:
    - Finalization of the v1.2.18 technical RFC.
    - Addition of the "Advanced Mouse Selection" section to `release-notes.md`.
    - Version badge bump and expansion of the "Static Reading Mode" section in `README.md`.
    - Addition of new mouse and scroll keybindings to the README navigation table.

## Capabilities

### New Capabilities
- `regression-auditing`: A formal verification process for auditing code changes against a baseline to ensure logic parity and stability.
- `release-packaging`: The systematic process of updating all user-facing documentation to match a code release milestone.

### Modified Capabilities
- None (Documentation and quality assurance phase).

## Impact

- **Reliability**: Mathematical confirmation that the new mouse selection engine did not break existing keyboard navigation or FSM states.
- **Discoverability**: Updated README and Release Notes ensure users are aware of the new `LMB` dragging and double-click seek features.
- **Auditability**: A clear record of the technical narrative and verification results for the v1.2.18 release.
