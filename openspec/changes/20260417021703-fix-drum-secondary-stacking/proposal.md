# Proposal: Fix Drum Secondary Stacking and Restore Manual Position Control

## Objective
Prevent overlap between primary and secondary subtitles in Drum Mode C when both are at the screen bottom, and restore the user's ability to use global keys (`r`, `t`) for manual fine-tuning.

## Context
When both primary and secondary subtitles are enabled in Drum Mode C and set to the BOTTOM position, the current stacking logic causes them to merge. This is because the script only calculates an offset for the height of one drum block, ignoring the second one. Furthermore, the `tick_drum` function hard-overwrites the `sec_pos` variable every frame based on its own calculation, which makes mpv's native `sub-pos` and `secondary-sub-pos` keyboard adjustments (`r`, `t`) ineffective.

## What Changes
1. **Remove Hard Override**: Stop `tick_drum` from ignoring the user's `secondary-sub-pos` setting.
2. **Improved Default Stacking**: Update the calculation to provde enough room for two full drum blocks.
3. **Configuration**: Adjust default `sec_pos_bottom` to provide better default spacing in Drum Mode.

## Capabilities

### Modified Capabilities
- `subtitle-rendering`: Improve layout coordination between multiple active tracks in Drum Mode.

## Impact
- **lls_core.lua**: Modifications to `tick_drum` and `Options`.
- **UX**: User recovers control over subtitle positioning via standard hotkeys.
