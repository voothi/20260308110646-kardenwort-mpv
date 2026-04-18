## Context

The rendering loop in `scripts/lls_core.lua` (specifically `draw_dw` and `draw_drum`) determines the color and formatting of subtitle tokens by iterating through several "Levels" of priority. The current state has database-driven highlights (Orange/Purple) occupying a higher priority tier than manual focus highlights (Bright Yellow), which prevents users from seeing where their cursor is positioned when it overlaps with a saved term. Additionally, a recent refactoring attempt left the script in a broken state due to a syntax error.

## Goals / Non-Goals

**Goals:**
- Correct the visual priority so that "Manual" ALWAYS beats "Automated".
- Restore the OSD rendering engine by fixing the syntax regression.
- Ensure consistent priority behavior across both the Drum Window (Mode W) and the Drum Mode OSD (Mode D).

**Non-Goals:**
- This change does not aim to implement "layering" (additive colors). One priority level will always win for a specific token.
- No changes to the `calculate_highlight_stack` logic itself (database matching rules remain the same).

## Decisions

- **Independent If-Blocks**: Transition from an `if/elseif` chain to a sequence of independent `if` blocks guarded by `meta.priority == 0`.
- **Priority Re-mapping**:
  - **Priority 1 (Top)**: Multi-word persistent selections (`Options.dw_ctrl_select_color`). Checked first.
  - **Priority 2**: Current Focus / LMB Drag Range (`Options.dw_highlight_color`). Checked second, guarded by `priority == 0`.
  - **Priority 3**: Database-driven matches (Orange/Purple/Brick). Checked third, guarded by `priority == 0`.
- **Consistency**: Apply the exact same priority logic to both `draw_drum` (line-by-line preview) and `draw_dw` (the full layout engine).

## Risks / Trade-offs

- **Visibility Trade-off**: When a word is focused (Bright Yellow), its underlying database color (Orange/Purple) is hidden. This is acceptable as Focus is transient and visual interaction clarity is paramount.
- **Complexity**: Adding more `if` blocks slightly increases the per-token evaluation cost, but for common subtitle lengths (5-10 words per line), this is negligible.
