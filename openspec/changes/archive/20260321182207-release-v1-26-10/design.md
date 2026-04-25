# Design: OpenSpec Integration and Agent Workflows

## System Architecture
The implementation follows the OpenSpec standard, placing specification and change artifacts within a top-level `openspec/` directory.

### Components
1.  **OpenSpec Core**: Directory structure (`openspec/changes/`, `openspec/specs/`).
2.  **Project Context**: `openspec/config.yaml` for repository-wide settings.
3.  **Agent Interface**: `AGENTS.md` (human-readable) and `.agent/workflows/` (machine-executable).
4.  **Workflow Automation**: Scripts and markdown-based workflows for common agent tasks.

## Data Structures
- **Change Record**: Metadata and task lists for specific features/releases.
- **Specification (Spec)**: Immutable requirements and design for a single feature.
- **Workflow Definitions**: Markdown files in `.agent/workflows/` that define step-by-step processes for the agent.

## Implementation Strategy
- **OpenSpec**: Adopt the directory layout.
- **Documentation**: Use `AGENTS.md` as the primary entry point for understanding agent capabilities.
- **Automation**: Map slash commands to the corresponding workflow files in the `.agent/` directory.
