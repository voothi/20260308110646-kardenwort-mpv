# Spec: OpenSpec Integration

## Context
The project needs a robust way to track changes and specifications that is compatible with AI agents.

## Requirements
- Maintain an `openspec/` root directory.
- Use `openspec/changes/` for tracking discrete units of work.
- Use `openspec/specs/` for long-lived feature specifications.
- Ensure all change artifacts include a `tasks.md` with checkable items.

## Verification
- Verify the presence of the `openspec/` directory.
- Confirm that new changes are created within `openspec/changes/`.
