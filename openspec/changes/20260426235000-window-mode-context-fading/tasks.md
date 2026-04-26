## 1. Configuration

- [x] 1.1 Add `dw_active_opacity` and `dw_context_opacity` to the `Options` table.
- [x] 1.2 Set default values to "00" and "30" respectively.

## 2. Rendering Implementation

- [x] 2.1 Update `draw_dw` to calculate `opacity` per line using `calculate_ass_alpha`.
- [x] 2.2 Inject the `\1a` tag into the `line_prefix` within the subtitle loop.
- [x] 2.3 Remove the redundant block-level `\1a` tag from the final OSD assembly.

## 3. Verification

- [x] 3.1 Verify that active lines in Mode W are more saturated than context lines.
- [x] 3.2 Verify that database highlights (yellow/purple/orange) on context lines are correctly faded.
- [x] 3.3 Verify that setting `dw_context_opacity = "00"` restores uniform saturation.
