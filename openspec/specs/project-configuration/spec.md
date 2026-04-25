# Spec: Project Configuration

## Context
AI agents need specific project context to provide accurate assistance and follow repository-specific rules.

## Requirements
- Maintain `openspec/config.yaml`.
- Define project-wide metadata (name, version, etc.).
- Specify rules for code style, testing, and documentation.
- Configure agent-specific behavior settings.

## Verification
- Confirm `openspec/config.yaml` exists and is valid YAML.
- Verify that agent behavior respects the rules defined in the configuration.
