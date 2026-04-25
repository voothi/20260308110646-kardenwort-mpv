# Spec: Hit-Test Multipliers

## Context
Fixed ratios fail when font sizes increase significantly, leading to selection drift.

## Requirements
- Introduce `dw_vline_h_mul`: Adjusts vertical height of a single line.
- Introduce `dw_sub_gap_mul`: Adjusts vertical height of gaps between subtitles.
- Introduce `dw_char_width`: Adjusts horizontal character spacing for selection.
- Integrate these into the `handle_mouse_event` logic in `lls_core.lua`.

## Verification
- Click a word at the top of the Drum Window and verify it highlights correctly.
- Click a word at the bottom of the Drum Window and verify it highlights correctly (testing cumulative vertical drift).
