# Specification: OSD Hit-Zone Sync

## Overview
All OSD rendering modes must maintain absolute parity between the visual vertical spacing (rendered via ASS tags) and the logical hit-zones (used for mouse interaction).

## Requirements

### Requirement: Unified Gap Calculation
- The gap between two subtitles (sub-gap) must be calculated using a single consistent formula across all renderers.
- **Formula**: `gap = (font_size * block_gap_mul)`
- If `double_gap` is enabled, an additional line height must be added: `gap = gap + (font_size * line_height_mul) + vsp`.

### Requirement: Visual Gap Implementation
- For OSD blocks containing multiple subtitles, the visual gap must be enforced using the `\vsp` ASS tag.
- If `double_gap` is `no`, the separator `\N` should be modified by `{\vsp[gap - default_line_height]}`.
- If `double_gap` is `yes`, the separator `\N\N` should be modified such that the total height matches the logical calculation.

#### Scenario: Subtitle Spacing Adjustment
- **WHEN** the user sets `block_gap_mul` to a negative value (e.g., `-0.27`)
- **THEN** both the visual OSD and the mouse hit-testing zones must contract by the same amount, ensuring no selection drift occurs.
