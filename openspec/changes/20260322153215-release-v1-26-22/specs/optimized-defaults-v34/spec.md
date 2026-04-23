# Spec: Optimized Defaults (v34)

## Context
A baseline calibration is needed for the recommended `dw_font_size=34` setting.

## Requirements
- Establish default values for `Consolas` at size 34:
    - `dw_vline_h_mul=0.87`
    - `dw_sub_gap_mul=0.6`
    - `dw_char_width=0.5`
- Ensure these values are hardcoded as defaults or provided in the standard `mpv.conf` template.

## Verification
- Use a standard 1080p video.
- Open Drum Window at font size 34.
- Verify that every word can be clicked accurately with these defaults.
