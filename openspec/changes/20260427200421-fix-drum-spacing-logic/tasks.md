## 1. Preparation and Core Logic

- [x] 1.1 Define `calculate_sub_gap(prefix, font_size, lh_mul, vsp)` helper function in `lls_core.lua` to centralize gap height logic.
- [x] 1.2 Identify all rendering loops in `draw_drum`, `draw_dw`, and `draw_tooltip` that use hardcoded `\N` or `\N\N` separators.

## 2. Rendering Updates

- [x] 2.1 Update `draw_drum` to use `calculate_sub_gap` for both hit-zone calculations and visual OSD separators.
- [x] 2.2 Update `draw_dw` to synchronize the visual `separator` with the `sub_gap` used in the layout engine.
- [x] 2.3 Update `draw_tooltip` to use the unified gap logic.
- [x] 2.4 Inject `{\vsp}` tags into subtitle separators to reflect the `block_gap_mul` fine-tuning visually.

## 3. UI and Feedback

- [x] 3.1 Update `cmd_toggle_drum` to show the active mode and gap state (e.g., "Drum Mode: ON [Double Gap: YES]").
- [x] 3.2 Add similar feedback to any other gap-toggling keybindings if they exist.

## 4. Verification

- [x] 4.1 Verify that setting `drum_block_gap_mul` to a negative value visually compresses subtitles and that mouse clicks still hit the correct words.
- [x] 4.2 Verify that `drum_double_gap=no` correctly switches the visual separator and hit-zones simultaneously.
- [x] 4.3 Ensure no regressions in "Regular Mode" (SRT style) when `srt_double_gap` is toggled.
