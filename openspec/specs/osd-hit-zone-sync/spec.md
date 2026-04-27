# Specification: OSD Hit-Zone Sync

## Overview
All OSD rendering modes must maintain absolute parity between the visual vertical spacing (rendered via ASS tags) and the logical hit-zones (used for mouse interaction).

## Requirements

### Requirement: Unified Gap Calculation
- The gap between two subtitles (sub-gap) must be calculated consistently across all renderers.
- **Double Gap**: `gap = (font_size * line_height_mul) + (font_size * block_gap_mul) + vsp`.
- **Single Gap**: `gap = 0` (The natural vertical advance of a single \N is assumed to match the `line_height_mul` calibration).
- This ensures that `block_gap_mul` acts as a specific "block-to-block" adjustment that does not interfere with the tightly-packed internal lines of a single-gap mode.

### Requirement: Visual Gap Implementation
- For OSD blocks containing multiple subtitles, the visual gap must be enforced using the `\vsp` ASS tag for double-gap modes.
- **Double Gap**: The separator `\N\N` must be wrapped in `\vsp` tags: `{\vsp(base + extra)}\N\N{\vsp(base)}`, where `extra` is `(font_size * block_gap_mul / 2)`.
- **Single Gap**: The separator is a standard `\N` with no extra `\vsp` scaling, relying on font-specific `LineAdvance`.
- The division by 2 for double-gap `\vsp` is required because libass applies the `\vsp` tag to each newline within the separator.

#### Scenario: Subtitle Spacing Adjustment
- **WHEN** the user sets `block_gap_mul` to a negative value (e.g., `-0.27`)
- **THEN** both the visual OSD and the mouse hit-testing zones must contract by the same amount, ensuring no selection drift occurs.
