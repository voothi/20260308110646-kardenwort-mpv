## Why

The user has rolled back to v1.82.26 due to visual regressions and complexity accumulated from previous attempts to transfer features (spacing, margins, borders, and tooltip positioning). The main issue resides in incorrect visual display of shading, borders, and frames (specifically under `osd-border-style=background-box` mode), text wrapping alignment issues, and off-center tooltips in fullscreen Drum Mode (DM).

This proposal establishes a plan to carefully and step-by-step transfer the visual improvements (spacing, padding, absolute centering, and border-box transparency overrides) into the current branch using a minimally invasive, phase-based approach.

## What Changes

1. **Decouple Line Height and Block Gaps**: Support separate visual line spacing inside wrapped subtitles and custom inter-subtitle gaps.
2. **Dynamic Safe-Area Edge Margins**: Prevent subtitle frames from touching screen edges under overflow conditions.
3. **Cyrillic Width Calibration**: Prevent long Russian tooltip translations from overflowing their background panels by adjusting proportional font calculations.
4. **Absolute Single Background Card**: Replace independent line-level background cards with a single premium semi-transparent vector box for both the Drum Window and interactive Tooltips.
5. **Localized Transparency Override**: Temporarily bypass global `background-box` style conflicts during active UI overlays (DW, Search, and Tooltips) without disrupting upper subtitles or console displays.
6. **Centering for Fullscreen Drum Mode Tooltips**: Ensure that in fullscreen Drum Mode (DM) the translation tooltip is horizontally centered at X = 960 and vertically positioned at the secondary subtitle area to prevent collisions.

## Capabilities

### New Capabilities
<!-- None needed, we are modifying existing ones -->

### Modified Capabilities
- `drum-window`: Decoupling visual line height from block gap multipliers, and adding edge margin safe-area constraints.
- `drum-window-tooltip`: Decoupling and centering the OSD tooltip overlay vertically and horizontally in fullscreen Drum Mode (DM).
- `drum-context`: Ensuring word-selection parity for trailing punctuation (e.g., periods, question marks) across both DM and DW.

## Impact

- `scripts/kardenwort/main.lua`: The rendering engine, mouse-move/hover checks, and OSD display blocks will be modified with minimally invasive insertions.
- `tests/`: Automated tests will be introduced or migrated in the final phase to prevent regressions without blocking prototyping.
