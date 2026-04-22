## Context

The repository contains a significant history of development documented in `.\docs\rfcs`. These files contain technical specifications, test cases, and design decisions that are not yet integrated into the OpenSpec system. This migration aims to formalize this knowledge.

## Goals / Non-Goals

**Goals:**
- Systematically migrate each RFC from `.\docs\rfcs` into a dedicated OpenSpec change.
- Extract high-quality specifications, including test cases and behavioral requirements.
- Use a checklist-driven approach to ensure no information is lost.
- Maintain a manual review step between each migration to ensure accuracy.

**Non-Goals:**
- Automatic synchronization with the main `openspec/specs/` directory (merging will be handled manually later).
- Modification of the existing codebase during the migration phase.

## Decisions

- **Granular Changes**: Each RFC file will be processed as its own OpenSpec change using the `/opsx-propose` command. This ensures that the extracted specifications are focused and manageable.
- **Naming Standard**: Directories will follow the pattern `<ZID>-<name>` to maintain a clear link to the original documents.
- **Checklist-Based Tracking**: A master checklist in `tasks.md` will be used to track progress through the 39 RFC files.

## Risks / Trade-offs

- **Risk**: Information overload if specs are too verbose.
- **Mitigation**: Focus on extracting "most valuable information" such as test cases and core logic.
- **Risk**: Inconsistency with current code.
- **Mitigation**: Review each proposal against the current codebase before finalizing.
