## Context

The Kardenwort-mpv project relies on a distributed set of specifications to maintain its complex behavior across multiple UI modes and interaction patterns. As the codebase grows, drift between implementation and specification becomes a risk. This change defines the methodology for a comprehensive compliance audit.

## Goals / Non-Goals

**Goals:**
- Verify implementation against all requirements in `openspec\specs`.
- Identify "Dead Specifications" (specs for features no longer present).
- Surface "Implementation Gaps" (requirements defined but not met).
- Produce a clear roadmap for stabilization.

**Non-Goals:**
- In-place bug fixing (fixing identified issues will be handled in subsequent changes).
- Updating specification requirements (requirements are considered the ground truth for this audit).

## Decisions

- **Spec Grouping**: Audit will be organized by functional domains:
  1. **Navigation & Seeking** (e.g., `unified-navigation-logic`, `tick-loop`)
  2. **UI & Rendering** (e.g., `x-axis-re-anchoring`, `variable-driven-rendering`)
  3. **Interaction & State** (e.g., `word-based-deletion-logic`, `universal-subtitle-search`)
- **Validation Method**: Static analysis of Lua scripts combined with logic trace checks against recorded behaviors/logs.
- **Reporting**: Results will be consolidated into a structured report within this change's artifacts.

## Risks / Trade-offs

- **Static Analysis Limits**: Without a live mpv environment, some dynamic rendering behaviors (e.g., OSD overlap) may be difficult to verify with 100% certainty.
- **Time Intensity**: The large number of specs requires a disciplined, high-level verification approach rather than exhaustive line-by-line testing for every minor requirement.
