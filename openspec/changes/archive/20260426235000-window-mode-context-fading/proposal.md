# Proposal: Window Mode Context Fading

## Problem Statement
In Drum Mode (Mode C), active subtitles are highlighted not just by color, but by relative saturation—surrounding context lines are semi-transparent (`30` alpha), making the active line's colors pop. In Window Mode (Mode W), all lines share a single opacity (`00` alpha), which results in a flatter visual experience where the focal point is less distinct.

## Proposed Change
Implement line-specific alpha rendering in the Drum Window (`draw_dw`). We will introduce `dw_active_opacity` and `dw_context_opacity` options to allow Window Mode to match the focal-point contrast of Drum Mode.

## Impact
- **Visual Clarity**: Makes the active subtitle track easier to identify at a glance within a large block of text.
- **Consistency**: Aligns the "Active vs Context" styling logic across all OSD modes.
- **Customization**: Users can now fine-tune the transparency of context lines in the Drum Window independently of the active line.
