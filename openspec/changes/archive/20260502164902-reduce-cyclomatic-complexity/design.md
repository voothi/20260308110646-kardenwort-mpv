# Design: Modular Architecture for LLS Core

## Context

The current implementation of `lls_core.lua` is a monolithic file where every feature is tightly coupled with every other feature. This creates a high risk of regressions and makes the code difficult to understand and maintain. The cyclomatic complexity is particularly high in the rendering and highlighting loops.

## Goals / Non-Goals

**Goals:**
- **Decoupling**: Separate logic from rendering and configuration.
- **Maintainability**: Reduce the size of `lls_core.lua` by at least 60%.
- **Readability**: Break down complex functions into small, single-responsibility helpers.
- **Consistency**: Standardize how OSD elements are rendered across different modes.

**Non-Goals:**
- Changing the user-facing UI or behavior (this is purely a structural refactor).
- Adding new features during the refactor.
- Modifying the external Anki database schema.

## Decisions

### 1. Modular Structure
We will use a directory-based modular structure:
- `scripts/lls_core.lua` (Orchestrator)
- `scripts/lib/diagnostic.lua` (Logging, Config Health)
- `scripts/lib/sub_parser.lua` (SRT/ASS Parsing, Tokenization)
- `scripts/lib/anki_manager.lua` (Anki logic, Highlighting engine)
- `scripts/lib/search_engine.lua` (Search logic, Match scoring)
- `scripts/lib/ui_renderer.lua` (ASS tag generation, Hit-zones, Layout)

### 2. Refactoring Highlighting Logic
The `calculate_highlight_stack` function will be refactored into a pipeline:
1. **Candidate Selector**: Uses binary search to find relevant highlights for the current time/segment.
2. **Sequence Matcher**: Verifies if tokens match the saved term sequence.
3. **Context Grounder**: Validates the match against surrounding words/pivots.
4. **Stack Calculator**: Aggregates verified matches into the final color/depth stack.

### 3. Centralized Rendering Utilities
A shared `ui_renderer` module will provide standardized methods for:
- Calculating ASS transparency (alpha) from opacity settings.
- Wrapping tokens into visual lines.
- Registering OSD hit-zones for interactivity.
- Constructing the final ASS event strings.

## Risks / Trade-offs

- **Risk**: Potential performance overhead from multi-file `require` calls and function indirection.
- **Mitigation**: Lua's `require` is fast after initial load. We will maintain existing caching mechanisms (`DRUM_DRAW_CACHE`, etc.) to ensure O(1) rendering performance.
- **Risk**: Regressions in complex edge cases (e.g., elliptical split-matches).
- **Mitigation**: Comprehensive manual testing across all selection modes before final archival.
