## Why

The "double gap" and vertical spacing logic in `lls_core.lua` is currently inconsistent and difficult to configure. Users reporting that `drum_double_gap=no` "doesn't work" are often victims of two underlying issues:
1. **Mode Confusion**: Vertical spacing is split across three independent settings (`srt_double_gap`, `drum_double_gap`, `dw_double_gap`), meaning changes to one do not affect the others, even if they look similar on screen.
2. **Visual/Logical Drift**: The OSD rendering engine uses hardcoded `\N` or `\N\N` separators, while the mouse hit-testing logic uses font-size-aware multipliers (`block_gap_mul`). This causes the interactive zones to drift away from the visible text when custom spacing is used.

## What Changes

- **Synchronize Visuals**: Update OSD rendering to use the `\vsp` ASS tag to visually reflect the spacing calculated by `block_gap_mul`, ensuring that what the user sees matches where they click.
- **Improved Feedback**: Clarify the active rendering mode in OSD messages when toggling gaps, helping users understand which configuration option is currently controlling their view.
- **Standardize Spacing Logic**: Unify the internal calculation for "gap height" across all renderers to ensure architectural parity.

## Capabilities

### New Capabilities
- `osd-hit-zone-sync`: Ensure all OSD rendering modes (Regular, Drum, Window) use identical spacing logic for both visuals (ASS tags) and logical hit-testing.

### Modified Capabilities
- `vsp-support`: Extend requirement to include visual gap simulation via `\vsp` in multi-subtitle OSD blocks.
- `hit-test-multipliers`: Ensure multipliers are applied to visual OSD separators, not just logical hit-zones.

## Impact

- `lls_core.lua`: `draw_drum`, `draw_dw`, and `draw_tooltip` rendering loops.
- `mpv.conf`: Documentation and recommended defaults.
