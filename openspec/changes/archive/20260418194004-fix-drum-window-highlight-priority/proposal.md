## Why

The current highlighting priority causes database-driven word highlights (Orange) to obscure active manual selections and focus points (Bright Yellow), leading to user confusion during interaction. Additionally, a syntax error in the priority logic recently caused the Drum Window and other OSD elements to stop rendering entirely.

## What Changes

- **Priority Refactoring**: Update the highlighting stack to ensure manual user selections (hover focus, drag selection) carry higher visual priority than automated database highlights (Orange/Purple), aligning the code with the formal specification.
- **Rendering Restoration**: Fix the syntax error (missing `end` statement) that caused the `lls_core.lua` script to fail and disabled the OSD.
- **Priority Protection**: Implement logic guards to prevent lower-priority highlighting passes from overwriting established higher-priority colors.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `window-highlighting-spec`: Clarify and enforce that manual focus and selection highlights (Bright Yellow) MUST override automated database highlights (Orange/Purple).

## Impact

- `scripts/lls_core.lua`: Significant changes to the character/word rendering loop in `draw_dw` and `draw_drum`.
- User Experience: Improved visual feedback when interacting with saved words.
