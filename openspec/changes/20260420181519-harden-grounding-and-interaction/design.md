## Context

The current `lls_core.lua` interaction engine implements a 10s base fuzzy window for highlights, which grows for longer phrases. However, a logic error in `calculate_highlight_stack` causes the window to grow based on total words rather than surplus words, leading to performance degradation and false positives for long quotes. Additionally, the "interaction shield" (lockout period after keypress) is fragmented across the codebase, leading to inconsistent hardware jitter suppression.

## Goals / Non-Goals

**Goals:**
- Fix the off-by-ten error in the adaptive temporal window calculation.
- Standardize the interaction shield duration to a system-wide 150ms.
- Eliminate hardcoded interaction constants in favor of configurable options.
- Refine shield triggers to be modifier-aware (ignore Ctrl/Shift).

**Non-Goals:**
- Refactoring the core hit-test logic or coordinate generation (already verified as compliant).
- Modifying the Anki database schema or TSV export format.

## Decisions

### 1. Surplus-Only Temporal Growth
**Decision**: Refactor `L920` to use `(#term_clean - 10)` as the multiplier for temporal expansion.
**Rationale**: This ensures that a 15-word phrase adds 2.5s (5 * 0.5) instead of 7.5s (15 * 0.5).
**Alternatives**: Using a logarithmic growth curve (too complex for the current linear requirement).

### 2. Universal Option-Driven Interaction Shield
**Decision**: Remove the hardcoded `0.150` constant from `manage_dw_bindings:nav` and replace it with `Options.dw_mouse_shield_ms / 1000`. Set the default value to `150` in the script's `Options` table.
**Rationale**: Centralizing the value makes it easier for users to tune for their specific mouse hardware (standardizing on the 150ms "Gold Standard" identified in the spec).
**Alternatives**: Hardcoding 150ms everywhere (not configurable).

### 3. Modifier-Aware Shield Triggers
**Decision**: Update the `nav` wrapper to check for modifier key states. 
**Rationale**: This prevents a "Ctrl" or "Shift" keydown event from locking the mouse, which is necessary for combo-clicks (e.g., Ctrl+Click for pair selection).
**Alternatives**: Locking on any keydown (prevents combos).

## Risks / Trade-offs

- **[Risk]** Increasing the shield to 150ms may feel "sluggish" to extremely fast users. → **Mitigation**: The value remains fully configurable via `script-opts`.
- **[Risk]** Math correction for window size reduces recall for extremely long, drifting segments. → **Mitigation**: 0.5s per surplus word is still a generous buffer, and the 60s split gap limit handles true scene-drifts.
