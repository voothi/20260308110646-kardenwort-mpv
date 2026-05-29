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
- **Do not** initialize full OpenSpec artifact directories or create junctions in the code root.
- The project root includes a redirection config file at `openspec/config.yaml` with the `projectRoot` option pointing directly to the Obsidian private vault directory (`U:\voothi.vault\kardenwort-mpv`).

This dynamically and transparently redirects all OpenSpec operations (such as `/opsx:propose`, `openspec new change`, `openspec status`, etc.) to write and read files directly inside the private vault, without requiring environment variables, symlinks, or custom wrappers. Both human developers and AI agents can execute standard OpenSpec commands seamlessly in the workspace root.

---
*Note: These capabilities are powered by OpenSpec and the specialized `.agent/` configurations.*

## Development Guidelines and Constraints

- **Do not save trial or temporary `.lua` scripts anywhere in this project.** Because MPV or other loaders can automatically scan and load scripts, experimental or trial Lua scripts saved in the workspace can conflict with the productive ones and cause runtime errors. All exploratory or experimental Lua code must be executed outside the workspace or cleaned up immediately, ensuring only stable, productive scripts remain in the repository.

