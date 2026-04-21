## Context

The middle-click export feature in `lls_core.lua` relies on a multi-stage string cleaning and context extraction process. If the result of the initial cleaning (tag/space stripping) is an empty string, the subsequent search loop enters an infinite state because Lua's `string.find` returns a result that doesn't advance the search pointer when the search pattern is empty. 

Additionally, the Drum Window's performance is currently hindered by redundant layout calculations and full TSV reloads.

## Goals / Non-Goals

**Goals:**
- Eliminate the "middle-click freeze" by hardening string search loops.
- Improve Drum Window responsiveness through layout caching.
- Optimize TSV updates to prevent UI stuttering.
- Audit and harden other `while` loops in the codebase.

**Non-Goals:**
- Complete refactoring of the monolithic `lls_core.lua`.
- Changing the visual design or user-facing behavior of the Drum Window.

## Decisions

### 1. Loop Hardening Pattern
**Decision**: Adopt a mandatory increment pattern for all `string.find` loops.
**Rationale**: Instead of `search_from = e + 1`, use `search_from = math.max(e + 1, s + 1)` or explicitly check `#pattern > 0`.
**Alternatives**: Using a safety counter (less elegant, but good as a fallback).

### 2. Layout Caching
**Decision**: Cache the `layout` table in `FSM.DW_LAYOUT_CACHE`.
**Rationale**: Hit-testing and OSD rendering both need the same layout data. Recalculating it dozens of times per second (on mouse move) is wasteful.
**Cache Invalidation**: Invalidate cache when `FSM.DW_VIEW_CENTER` changes, tracks change, or relevant styling options change.

### 3. TSV Append Strategy
**Decision**: Manually inject new rows into `FSM.ANKI_HIGHLIGHTS` instead of calling `load_anki_tsv(true)`.
**Rationale**: Adding one row is O(1) in memory, whereas re-parsing a 5000-line TSV is O(N) and blocks the main Lua thread.

## Risks / Trade-offs

- **[Risk] Cache Inconsistency** → **Mitigation**: Ensure all state changes that affect layout (view center, track changes) explicitly clear the cache.
- **[Risk] TSV Divergence** → **Mitigation**: The background `anki_sync` timer will still occasionally perform a full re-sync using the file fingerprint, ensuring long-term consistency.
