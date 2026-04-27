# Spec: Hit-Test Multipliers

## Context
Fixed ratios fail when font sizes increase significantly, leading to selection drift.

## Requirements
- Introduce `dw_vline_h_mul`: Adjusts vertical height of a single line.
- Introduce `dw_sub_gap_mul`: Adjusts vertical height of gaps between subtitles.
- Introduce `dw_char_width`: Adjusts horizontal character spacing for selection.
- Integrate these into the `handle_mouse_event` logic in `lls_core.lua`.

### Requirement: Cross-Mode Parity
All `_block_gap_mul` settings (drum, srt, dw) must be applied to the visual separator only when double-gap mode is active.

#### Scenario: Switching Rendering Modes
- **WHEN** the user toggles between Regular and Drum Mode
- **THEN** the visual spacing must update to reflect the active mode's `_block_gap_mul` and `_vsp` settings, maintaining synchronization with hit-testing.

## Verification
- Click a word at the top of the Drum Window and verify it highlights correctly.
- Click a word at the bottom of the Drum Window and verify it highlights correctly (testing cumulative vertical drift).
