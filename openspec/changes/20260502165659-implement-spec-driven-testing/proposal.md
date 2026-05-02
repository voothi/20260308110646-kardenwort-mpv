## Why

The project currently relies on manual user verification to detect regressions, which is slow and prone to oversight. While AI agents can perform audits, doing so for every change is prohibitively expensive in terms of tokens and time. We need a deterministic, local mechanism to emulate user behavior and verify script state against formal specifications.

## What Changes

- **Test Harness**: A CLI-based tool (Python or PowerShell) to boot mpv in headless mode and interact with it via JSON IPC.
- **Diagnostic API**: New `script-message` hooks in `lls_core.lua` to expose internal state (hit-zones, OSD content, FSM variables) to the test harness.
- **Specification Mapping**: Logic to parse `spec.md` scenarios and execute corresponding test steps.
- **Aesthetic Validation**: Support for verifying rendering aesthetics (color, weight, opacity) by inspecting ASS tags in the OSD overlay data.

## Capabilities

### New Capabilities
- `automated-acceptance-testing`: Infrastructure for executing BDD-style scenarios against a running mpv instance.

### Modified Capabilities
- `lifecycle-reporting`: Expanded to include deep state reporting for automated diagnostics.

## Impact

- `scripts/lls_core.lua`: Addition of test-only hooks and state exposure.
- `openspec/`: Formalization of test scenarios within existing and new specs.
- New `tests/` directory: Containing the test driver and orchestration scripts.
