## Context

Users are confused by the interplay between `drum_double_gap`, `srt_double_gap`, and the `_block_gap_mul` settings. Currently, the visual spacing in OSD modes (Regular and Drum) is restricted to integer multiples of the line height (`\N` or `\N\N`), while the logical hit-testing zones for mouse interaction use fractional multipliers. This leads to:
1. **Interactive Dead Zones**: Clicks on visible text being ignored or triggering the wrong line.
2. **Visual Stagnation**: Setting `block_gap_mul` to a negative value does not visually compress the subtitles in OSD mode, even though it affects hit-testing.
3. **Semi-automatic Adjustment Failure**: The semi-automatic adjustment mechanism fails to operate normally in double interval mode or when `drum_double_gap=no`.

The implementation will integrate fixes and logic from a commit root `4c4bfca22b51e522a579d4605ec5357edeb4df4c` along with two specific branches (`93db0ae538d990e0463a9a689db9eff704b1a0ea` and `828967d07419d361540e1750712b9eefd63cca84`).

## Goals / Non-Goals

**Goals:**
- Unify the vertical gap calculation logic across all rendering functions.
- Synchronize visual OSD rendering with the logical hit-testing zones.
- Improve user feedback when toggling gap settings.
- Fix the semi-automatic adjustment mechanism so it correctly processes coefficients in double interval mode and handles `drum_double_gap=no`.

**Non-Goals:**
- Merging the three independent gap settings into one (preserving existing flexibility).
- Refactoring the entire OSD rendering system to move away from single-block ASS.

## Decisions

### 1. Centralized Gap Calculation
Implement a helper function `calculate_sub_gap(prefix, font_size, lh_mul, vsp)` to ensure consistency.
- **Formula (Double Gap)**: `(font_size * lh_mul) + (font_size * Options[prefix .. "_block_gap_mul"]) + vsp`.
- **Formula (Single Gap)**: `0` (natural `\N` advance covers the hit-zone when `lh_mul` is calibrated to the font's line-height).
- This decoupling allows the same `block_gap_mul` coefficient to work across both modes by treating it strictly as a "block gap" adjustment rather than a "line gap" adjustment.

### 2. Visual Gap Synchronization via `\vsp`
Modify the `get_separator` function in `draw_drum`, `draw_dw`, and `draw_tooltip` to include an inline `\vsp` tag for double-gap modes.
- **Implementation (Double Gap)**: `string.format("{\\vsp%g}\\N\\N{\\vsp%g}", vsp_base + (line_fs * b_gap_mul / 2), vsp_base)`.
- **Implementation (Single Gap)**: `\\N` (standard newline, no `vsp_extra`).
- The `/ 2` division compensates for the fact that `\N\N` hits the `\vsp` tag twice in ASS layout logic.
- Restoring `vsp_base` after the newline ensures global `vsp` settings are preserved for subsequent lines.

### 3. Semi-automatic Adjustment Mechanism Integration
Review and integrate the solutions from branches `93db0ae538d990e0463a9a689db9eff704b1a0ea` and `828967d07419d361540e1750712b9eefd63cca84`. Adjust the semi-automatic coefficient scaling so that it properly accounts for the state of `drum_double_gap` and interval modes, resolving the inconsistencies reported.

### 4. Clearer OSD Toggles
Update `cmd_toggle_drum` and related functions to include the active mode in the feedback message (e.g., "Drum Mode: ON [Gap: ON]").

## Risks / Trade-offs

- **ASS Rendering Limits**: Some versions of libass might handle `\vsp` differently if multiple tags are present in one block. We will place the `\vsp` tag at the start of each subtitle separator to reset it for the next block.
- **Subtitle Multi-line Spacing**: If a single subtitle contains internal newlines, `\vsp` will affect them as well. Since LLS typically flattens or handles multi-line subs as single units in these modes, this is an acceptable trade-off for overall hit-zone accuracy.
