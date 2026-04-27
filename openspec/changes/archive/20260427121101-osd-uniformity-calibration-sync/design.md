# Design: OSD Uniformity and Semi-Automatic Calibration

## Context
The project uses multiple OSD overlays to display subtitles, translations, and navigation lists. These overlays currently use slightly different ASS formatting tags and inconsistent calibration logic, leading to visual "jumps" in brightness and misaligned mouse hit-zones when spacing is adjusted.

## Goals / Non-Goals

**Goals:**
- **Visual Synchronization**: Achieve 100% visual parity (brightness, sharpness, font weight) between Drum Window, Drum Mode, and Tooltip.
- **Dynamic Calibration**: Link the technical click-zones directly to visual configuration parameters.
- **Styling Uniformity**: Align the configuration schema for all modes so they are functionally identical.

**Non-Goals:**
- Changing the core rendering engine of mpv.
- Adding new font families beyond the currently supported monospace (Consolas) and sans-serif (Inter).

## Decisions

### 1. Rendering Unification
- **Primary Color Tag**: Standardize on `\1c` instead of `\c` to ensure the renderer treats the primary text layer consistently across all overlays.
- **Wrap Style**: Enforce `\q2` (No Wrap) for all list-based displays. This prevents mpv from applying any "smart wrapping" or layout softening that could cause brightness discrepancies.
- **Opacity Consistency**: Ensure `calculate_ass_alpha` is used consistently for `\1a`, `\3a`, and `\4a` across all modes.

### 2. Semi-Automatic Calibration Logic
- **Vertical Height**: The height of a logical line in the hit-testing map is calculated as `(Options.xx_font_size * Options.xx_line_height_mul) + Options.xx_vsp`.
- **Gap Handling**: The inter-subtitle gap is calculated as `(Options.xx_font_size * Options.xx_block_gap_mul) + (double_gap ? vline_h : 0)`.
- **Source of Truth**: Visual parameters in `mpv.conf` (like `dw_vsp` or `dw_double_gap`) become inputs for the calibration engine.

### 3. Global Parity standard
- All modes (`srt`, `dw`, `drum`, `tooltip`) are enforced to use identical visual defaults:
    - **Font**: Consolas, Size 34.
    - **Spacing**: `line_height_mul = 0.87`, `block_gap_mul = -0.27`, `double_gap = yes`.
- This ensures that a single calibration value (`-0.27`) provides identical mouse accuracy across the entire suite.

### 4. Tooltip Centering
- **Precision Alignment**: When `tooltip_y_offset_lines=0`, the active line of the tooltip is centered exactly on the middle of the target "white line" in Window W (Drum Window) or Window E (Tooltip).
- **Formula**: `final_y = osd_y + (Options.tooltip_y_offset_lines * layout_line_h)`.
- **Consistency**: This alignment logic is independent of the number of context lines or clamping, ensuring a stable visual anchor during interaction.

## Risks / Trade-offs
- **Migration Necessity**: To maintain legacy accuracy with the new "smarter" gap detection, users must migrate `block_gap_mul` to `-0.27` (if using Consolas 34 and Double Gaps).
- **No-Wrap Risk**: Using `\q2` means text will simply cut off if it exceeds the OSD width, but this is already the expected behavior for the Drum Window and list-based layouts.
