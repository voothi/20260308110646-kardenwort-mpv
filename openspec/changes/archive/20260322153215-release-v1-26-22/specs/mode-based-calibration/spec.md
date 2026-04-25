# Spec: Mode-Based Calibration

## Context
Different font sizes require different multiplier sets.

## Requirements
- Organize `mpv.conf` to group font size with its corresponding multipliers.
- Provide clear labels for different calibration "Modes".
- Ensure that updating the mode settings correctly overrides the script's internal defaults.

## Verification
- Switch from "Mode 1" (default) to "Mode 2" (calibrated for font 34) in `mpv.conf`.
- Verify that selection accuracy is improved at the higher font size.
