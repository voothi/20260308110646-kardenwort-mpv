# Spec: Slash Commands Implementation

## Context
Slash commands provide a convenient way for users to trigger complex agent workflows.

## Requirements
- Implement `/opsx-propose`: Trigger change proposal generation.
- Implement `/opsx-apply`: Trigger task implementation.
- Implement `/opsx-archive`: Trigger change finalization and archival.
- Implement `/opsx-explore`: Trigger collaborative thinking/debugging mode.
- Ensure all commands are defined in `.agent/workflows/`.

## Verification
- Test each slash command to ensure it triggers the correct workflow file.
- Verify that workflow steps are correctly interpreted by the agent.
