## Why

The translation tooltip currently renders differently in Drum Window (DW) and Drum Mode (DM): DW shows the desired single translucent card, while DM can inherit native `background-box` behavior and produce extra dark per-line frames. This keeps resurfacing because the tooltip rendering path is shared in places but its style lifecycle is still mode-specific.

## What Changes

- Define a single tooltip rendering contract used by DW, DM, and styled SRT tooltip activation.
- Treat tooltip presentation as one shared custom OSD surface, independent of whether the parent subtitle context is DW or DM.
- Move tooltip-specific border/background decisions into the tooltip renderer or a small shared style helper instead of relying on mode-local `osd-border-style` assumptions.
- Ensure DM tooltips visually match the DW tooltip card by default: one measured vector background, no native per-line dark boxes, consistent outline/shadow/text styling.
- Preserve existing tooltip targeting, hit-zone, wrapping, cache, and secondary-subtitle fallback behavior.
- Add regression coverage that guards against DM/DW tooltip visual divergence and accidental reintroduction of `{\\bord0}{\\shad0}` or native background-box leakage.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `drum-window-tooltip`: Tooltip rendering requirements now cover parity across DW, DM, and styled SRT activation, not only the Drum Window lineage.
- `dynamic-osd-border-override`: Border override ownership must cover shared tooltip surfaces so custom tooltip overlays are not affected by native background-box state.
- `subtitle-rendering`: Tooltip rendering in Drum Mode must use the same visual style contract as the shared tooltip renderer while preserving visibility and hit-zone guards.

## Impact

- Affects `scripts/kardenwort/main.lua`, primarily `draw_dw_tooltip`, `apply_tooltip_ass`, tooltip activation paths, and border override management.
- Affects regression tests around tooltip ASS generation, DM/DW parity, and `osd-border-style=background-box`.
- No new runtime dependency or user-facing breaking change is expected.
