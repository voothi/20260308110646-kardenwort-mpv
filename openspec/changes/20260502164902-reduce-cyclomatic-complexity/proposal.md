# Proposal: Reduce Cyclomatic Complexity and Modularize Codebase

## Problem Statement

The `lls_core.lua` script has grown into a "God Object" exceeding 6,800 lines. It currently handles configuration, state management, subtitle parsing, Anki integration, search logic, and multiple rendering modes. This centralization has led to:
- **High Cyclomatic Complexity**: Functions like `calculate_highlight_stack` and `draw_drum` are dense and difficult to debug.
- **Fragility**: Changes in one system (e.g., highlighting) frequently cause regressions in others (e.g., rendering).
- **Maintenance Overhead**: The sheer size of the file makes it difficult for both humans and AI agents to navigate and reason about the code.

## Proposed Solution

We will modularize the codebase by extracting domain-specific logic into a new `lib/` directory and refactoring complex functions into smaller, focused helpers. `lls_core.lua` will be transitioned into a lean orchestrator that initializes these modules and manages high-level event flows.

## What Changes

- **Code Structure**: Introduction of a `scripts/lib/` directory for modularized components.
- **LLS Core**: Significant reduction in size of `lls_core.lua` as logic is migrated to libraries.
- **Internal APIs**: Formalization of internal interfaces between the core and its modules (Anki, Search, Rendering).
- **Highlighting Engine**: Refactoring of `calculate_highlight_stack` into discrete, manageable sub-functions.

## Capabilities

### New Capabilities
- `modular-architecture`: Transition to a multi-file architecture to improve maintainability and separate concerns.
- `shared-rendering-utils`: Centralized utilities for ASS tag generation and OSD layout management.

### Modified Capabilities
- `diagnostic-system`: Move configuration validation and logging into a standalone module.
- `anki-integration`: Extract Anki TSV handling and term mapping into a dedicated logic module.
- `search-engine`: Decouple search scoring and UI rendering from the core interaction loop.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (major refactor), new files in `scripts/lib/`.
- **Dependencies**: No new external dependencies; utilizing standard Lua/MPV features.
- **Systems**: Significant improvement in architectural integrity and performance through optimized logic paths.
