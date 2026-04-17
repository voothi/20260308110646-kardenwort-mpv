## Why

In Drum Window (Mode W), users can highlight words using two methods: a standard selection (yellow) and a persistent Ctrl + LMB selection (muted yellow). Currently, the standard yellow selection takes visual priority over the muted yellow selection. This makes it impossible for users to see if a word is already part of their Ctrl-selection set when the regular cursor or selection drag is positioned over it.

## What Changes

- **Selection Priority Swap**: Modify the Drum Window renderer to prioritize the Ctrl + LMB selection color (`dw_ctrl_select_color`) over the standard selection/cursor color (`dw_highlight_color`).
- **Visual Feedback Continuity**: Ensure that words marked for paired selection (Ctrl + LMB) remain visually distinct even when hovered or included in a drag-selection range.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `subtitle-rendering`: Update the Drum Window (Mode W) highlight priority to ensure non-contiguous (Ctrl + LMB) selections remain visible under the standard selection cursor.

## Impact

- **Affected File**: `scripts/lls_core.lua` (specifically the `draw_dw` function).
- **Behavioral Impact**: No change to functional logic; purely a visual layering change in the ASS OSD rendering loop for the Drum Window.
