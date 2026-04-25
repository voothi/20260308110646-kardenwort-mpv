# Spec: Folder Name Standardization

## Context
Inconsistent naming between documentation and the filesystem leads to maintenance friction.

## Requirements
- The agent configuration directory must be named `.agent/`.
- All documentation (starting with `AGENTS.md`) must refer to this directory as `.agent/`.
- Plural forms (like `.agents/`) must be removed from documentation unless referring to multiple agents generally.

## Verification
- Confirm that `.agent/` exists in the repository root.
- Verify that `grep` or search for `.agents/` in `AGENTS.md` returns no matches.
