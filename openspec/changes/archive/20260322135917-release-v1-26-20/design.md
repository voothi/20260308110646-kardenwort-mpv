# Design: Agent Config Standardization

## System Architecture
This change is purely documentation-focused and ensures synchronization between the codebase's metadata and the physical directory structure.

### Components
1.  **Agent Metadata (`AGENTS.md`)**:
    - Centralized guide for agent capabilities.
    - Updated to correctly link to the `.agent/` configuration directory.
2.  **Filesystem Structure**:
    - The `.agent/` directory remains the source of truth for agent-specific logic and workflows.

## Implementation Strategy
- **Text Replacement**: Audit `AGENTS.md` and other root-level markdown files for the string `.agents/` and replace it with `.agent/`.
- **Consistency Check**: Verify that all future references to the agent configuration folder adhere to the singular form.
