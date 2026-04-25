# Proposal: Drum Window Hit-Test Calibration (v1.26.22)

## Problem
Increasing the Drum Window font size to 34 caused a regression in mouse click accuracy. The hardcoded hit-test ratios did not scale linearly with the larger font, making word selection difficult.

## Proposed Change
Implement configurable hit-test multipliers to decouple visual layout from selection logic, allowing for fine-tuned calibration at any font scale.

## Objectives
- Restore precise mouse selection for font size 34 and above.
- Decouple hit-test grid calculations from hardcoded font size ratios.
- Provide a mode-based configuration for easy switching between calibration sets.
- Establish optimized default values for the Consolas font.

## Key Features
- **Configurable Hit-Test Multipliers**: New parameters for line height, subtitle gap, and character width compensation.
- **Mode-Based Calibration**: Structured `mpv.conf` entries for quick swapping of font/hit-test presets.
- **Calibrated Defaults**: Precision-tuned values for the current 34px baseline.
