# Capability: Modular Architecture

## ADDED Requirements

### Requirement: Multi-file Structure
The system SHALL organize logic into discrete modules within a `scripts/lib/` directory to improve maintainability.

#### Scenario: Successful module load
- **WHEN** `kardenwort/main.lua` starts
- **THEN** it SHALL successfully load all library modules via `require` or equivalent mechanism.

### Requirement: Centralized Diagnostic Interface
All modules SHALL utilize a centralized diagnostic and logging interface to ensure consistent console output and error reporting.

#### Scenario: Unified logging
- **WHEN** an error occurs in the `sub_parser` module
- **THEN** it SHALL be logged through the `Diagnostic` module with the `[Kardenwort]` prefix.

### Requirement: Decoupled Rendering Pipeline
The rendering logic SHALL be decoupled from state management, using a standardized utility module for OSD layout and ASS tag generation.

#### Scenario: Consistent highlight styling
- **WHEN** rendering highlights in Drum Window or SRT mode
- **THEN** both SHALL use the shared `ui_renderer` to apply consistent font weights and colors.

### Requirement: Isolated State Management
Feature-specific state (e.g., search query, drum window cursor) SHALL be isolated within module-scoped tables to prevent namespace pollution.

#### Scenario: Independent state updates
- **WHEN** the search query is updated
- **THEN** it SHALL NOT affect the state of the Drum Window cursor unless explicitly coordinated.

