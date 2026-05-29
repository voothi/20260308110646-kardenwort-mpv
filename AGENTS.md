# Agent Capabilities

This document outlines the specialized skills and workflows available to the AI agents within this repository.

## Specialized Skills

These skills extend the agent's core capabilities for specific tasks:

| Skill | Description |
|-------|-------------|
| **openspec-apply-change** | Implement tasks from an OpenSpec change. Used to systematically work through a planned implementation. |
| **openspec-archive-change** | Finalize and archive a completed change, ensuring specifications are updated. |
| **openspec-explore** | A "thinking mode" for brainstorming, architecture review, and problem investigation without making code changes. |
| **openspec-propose** | Rapidly generate a full change proposal, including design and tasks, from a simple description. |

## Workflows (Slash Commands)

Use these commands in chat to trigger specific agent behaviors:

| Command | Purpose |
|---------|---------|
| `/opsx:apply` | Start or continue implementing a planned change. |
| `/opsx:archive` | Close out a completed task and archive the history. |
| `/opsx:explore` | Enter a collaborative thinking space to discuss ideas or debug issues. |
| `/opsx:propose` | Quickly turn an idea into a structured plan ready for implementation. |

## Crucial OpenSpec Configuration (Multi-Repository Strategy)

To keep the codebase and documentation separate and protect documentation from Git rollbacks:
- **Do not** initialize OpenSpec or create junctions in the code root.
- **Do** set the `OPENSPEC_PROJECT_ROOT` environment variable to the Obsidian private vault directory (`U:\voothi.vault\kardenwort-mpv`) when executing any OpenSpec command.

### PowerShell Command Examples:
When running OpenSpec commands in PowerShell, always prefix the command with the environment variable:
```powershell
$env:OPENSPEC_PROJECT_ROOT="U:\voothi.vault\kardenwort-mpv"; openspec new change "20260529165154-my-change"
```
Or set it once for the session:
```powershell
$env:OPENSPEC_PROJECT_ROOT="U:\voothi.vault\kardenwort-mpv"
```

This ensures all proposal, specification, design, and task files are read/written directly inside the private vault, keeping your public code repository clean and binary-free.

---
*Note: These capabilities are powered by OpenSpec and the specialized `.agent/` configurations.*
