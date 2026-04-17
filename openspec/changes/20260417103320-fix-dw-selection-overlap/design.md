## Context

In `scripts/lls_core.lua`, the `draw_dw` function handles the visual rendering of the Drum Window (Mode W). It computes formatting for each word by checking its state (selected, part of a Ctrl-pending set, part of an Anki deck, etc.). 

The current state machine prioritizing "current drag selection" or "cursor position" over "persistent paired word selections" leads to visibility loss when these overlap.

## Goals / Non-Goals

**Goals:**
- Ensure `dw_ctrl_select_color` (muted yellow) is always visible on words that have been explicitly added to the multi-word selection set, regardless of standard cursor position or drag selection.
- Maintain existing highlighting for standard selections on words *not* in the Ctrl set.

**Non-Goals:**
- Modifying the logic for `draw_drum` (standard Drum Mode C), which does not support the same selection interactions.
- Changing color values or transparency settings.

## Decisions

### Decision: Reorder the `if-elseif` formatting chain
The word-level formatting loop in `draw_dw` will be modified to check the `FSM.DW_CTRL_PENDING_SET` membership **before** checking the `selected` range boolean.

- **Rationale**: User interaction with Ctrl + LMB is more specific and persistent than a transient cursor hover or drag selection. Overriding the regular cursor highlight with the Ctrl selection color provides better feedback for complex multi-word selection tasks.
- **Alternatives Considered**: 
  - *Color Blending*: Attempting to blend the colors in ASS. (Rejected: Too complex for OSD and likely to result in muddy, non-standard colors).
  - *Border Highlighting*: Using border colors to indicate Ctrl selection. (Rejected: Inconsistent with the current design language of the script).

## Risks / Trade-offs

- **[Risk] Confusing selection state** → **Mitigation**: Standard selection color is vibrant yellow, while Ctrl selection is muted yellow. The difference in hue/saturation remains distinct enough that "skipping" the standard highlight on a Ctrl-selected word will still be intuitive (the word remains "marked", just in its permanent set color).
