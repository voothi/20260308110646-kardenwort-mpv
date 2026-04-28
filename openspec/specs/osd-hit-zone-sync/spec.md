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
- **Single Gap**: The separator MUST use the `\vsp` tag to enforce pixel-parity with the `drum_gap_adj` parameter: `{\vsp(base + adj)}\N{\vsp(base)}`.
- The division by 2 for double-gap `\vsp` is required because libass applies the `\vsp` tag to each newline within the separator.

#### Scenario: Subtitle Spacing Adjustment
- **WHEN** the user sets `block_gap_mul` to a negative value (e.g., `-0.27`)
- **THEN** both the visual OSD and the mouse hit-testing zones must contract by the same amount, ensuring no selection drift occurs.

### Requirement: Cumulative Calibration Adjustment
- In single-gap mode (`drum_double_gap=no`), if the natural font vertical advance does not perfectly match the `line_height_mul` calibration, the system SHALL support a cumulative adjustment via `drum_gap_adj`.
- **Cumulative Correctness**: The adjustment MUST be applied to both the `total_h` calculation (which offsets the starting position of the OSD block) and the `cur_y` iteration (which places individual hit-boxes).
- **Anchor-Aware Calibration**: The adjustment SHALL apply to all lines relative to the OSD anchor (`\an2` vs `\an8`). This ensures that the active center line and context lines can be calibrated against cumulative vertical drift.

#### Scenario: Calibrating Vertical Drift
- **WHEN** the user observes that hit-zones are slightly misaligned with the visual text.
- **THEN** setting `drum_gap_adj` to a specific pixel value SHALL shift the hit-zones and visual OSD text in perfect sync to restore alignment across the entire block.

