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

---
*Note: These capabilities are powered by OpenSpec and the specialized `.agent/` configurations.*
