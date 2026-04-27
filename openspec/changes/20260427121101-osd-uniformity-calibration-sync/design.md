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
- **Layering**: Ensure that only one primary subtitle display (Drum Mode or Drum Window) is active at a time to prevent "Double Rendering" brightness stack.

### 2. Semi-Automatic Calibration Logic
- **Vertical Height**: The height of a logical line in the hit-testing map will be calculated as `(Options.xx_font_size * Options.xx_line_height_mul) + Options.xx_vsp`.
- **Gap Handling**: The inter-subtitle gap will automatically expand by one full line height if `double_gap` is enabled.
- **Source of Truth**: Visual parameters in `mpv.conf` (like `dw_vsp` or `dw_double_gap`) become inputs for the calibration engine.

### 3. Schema Alignment
- Add missing styling parameters (`active_bold`, `context_bold`, `active_size_mul`, `context_size_mul`, `vsp`, `double_gap`) to all mode blocks in the `Options` table.

### 4. Tooltip Centering
- **Precision Alignment**: When `tooltip_y_offset_lines=0`, the active line of the tooltip is centered exactly on the middle of the target "white line" in Window W (Drum Window) or Window E (Tooltip).
- **Consistency**: This alignment logic is independent of the number of context lines or clamping, ensuring a stable visual anchor during interaction.

## Risks / Trade-offs
- **Legacy Offset**: Users with highly customized manual calibrations might need to adjust their `_mul` values slightly to account for the new "smarter" logic.
- **No-Wrap Risk**: Using `\q2` means text will simply cut off if it exceeds the OSD width, but this is already the expected behavior for the Drum Window and list-based layouts.
