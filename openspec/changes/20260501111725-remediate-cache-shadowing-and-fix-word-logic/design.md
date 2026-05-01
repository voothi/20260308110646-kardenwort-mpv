## Context

The `kardenwort-mpv` script uses a three-tiered rendering cache system. To prevent stale OSD state, a centralized `flush_rendering_caches()` function was implemented. However, due to Lua's lexical scoping and the use of the `local` keyword during table initialization later in the module, the flush function currently targets a different (outer) set of variables than the ones used by the rendering functions. Additionally, unoptimized logic was inadvertently re-introduced via shadowing.

## Goals / Non-Goals

**Goals:**
- Restore functional cache invalidation by ensuring `flush_rendering_caches` and rendering functions share the same table instances.
- Re-enforce O(1) character lookup performance for all navigation and hit-testing logic.
- Ensure mode transitions (Drum vs. SRT) are immediately reflected in the OSD.

**Non-Goals:**
- Modifying the core rendering logic or visual styles.
- Adding new configuration options.

## Decisions

### 1. Module-Level Scope Binding
The forward declarations at the top of the file must be the *only* declarations for the cache tables.
- **Decision**: Remove the `local` keyword from `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` assignments at lines 2918 and 3232.
- **Rationale**: In Lua, `local x` inside a chunk creates a new variable that shadows any existing variable named `x`. By removing `local`, the assignments correctly target the module-level variables captured by the `flush_rendering_caches` closure.

### 2. Removal of Shadowed Unoptimized Logic
- **Decision**: Delete the second definition of `is_word_char` at line 1395.
- **Rationale**: The first definition (line 913) is already optimized with `WORD_CHAR_MAP`. The second definition is redundant and slower. Removing it ensures that all code below line 1395 uses the optimized version.

### 3. Sentinel Hardening
- **Decision**: Add `DRUM_DRAW_CACHE.is_drum = false` to `flush_rendering_caches`.
- **Rationale**: This ensures that even if the track hasn't changed, a mode toggle will force a cache mismatch and trigger a rebuild of the ASS string.

## Risks / Trade-offs

- **[Risk]** Accidental global leakage → **[Mitigation]** The variables are already declared as `local` at the top of the module (line 14), so removing the second `local` keyword safely binds them to the module scope, not the global scope.
