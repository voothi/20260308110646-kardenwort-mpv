# Spec: Softer Scaling Formula

## Context
Strict 1080p font locking causes excessive word wrapping on small windows.

## Requirements
- Implement the formula: `comp_scale = 1.0 + (perfect_comp - 1.0) * strength`.
- Use 1080 as the reference height.
- Ensure the formula handles both upscaling (small windows) and downscaling (large monitors) gracefully.

## Verification
- At `strength = 1.0`, the font size should remain physically the same regardless of window size.
- At `strength = 0.5`, the font size should grow/shrink at half the rate of the window resize.
- At `strength = 0.0`, no scaling should occur (standard mpv behavior).
