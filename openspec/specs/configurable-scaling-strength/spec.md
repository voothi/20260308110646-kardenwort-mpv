# Spec: Configurable Scaling Strength

## Context
Users have different preferences for font size stability vs. layout density.

## Requirements
- Add `font_scale_strength` to the `Options` table.
- Default the value to `0.5` (balanced).
- Expose this option via `script-opts` in `mpv.conf`.

## Verification
- Change `font_scale_strength` in `mpv.conf` and restart mpv.
- Confirm the new scaling behavior matches the updated setting.
