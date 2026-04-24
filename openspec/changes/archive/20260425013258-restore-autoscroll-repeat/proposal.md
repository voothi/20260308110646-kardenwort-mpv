# Proposal: Restore Auto-scrolling Repeat Behavior

## Objective
Restore the auto-scrolling (key repeat) functionality for the `a` and `d` keys in all Drum Window modes (Normal, Single Line, Reel, Window).

## Why
Recent changes to the key binding system in `lls_core.lua` migrated hardcoded bindings to a dynamic `parse_and_bind` system. However, the `a` and `d` keys were bound without the `complex` flag, which prevents the script from receiving the "up" events necessary for the custom repeat timer logic in `cmd_seek_with_repeat`. This caused the keys to only trigger once per press, breaking the "hold-to-scroll" feature.

## What Changes
- Modify the `parse_and_bind` function in `lls_core.lua` to accept a `complex` flag for keyboard bindings.
- Update the `dw-seek-prev` and `dw-seek-next` bindings to use this `complex` flag.
- Ensure that the `cmd_seek_with_repeat` function receives the event table correctly to manage the repeat timer.

## Capabilities

### Modified Capabilities
- `seek-navigation`: Restored the ability to hold `a`/`d` (ф/в) keys to continuously seek through subtitles.

## Impact
- **lls_core.lua**: Modification of `parse_and_bind` and its call sites.
- **User Experience**: Restoration of native-feeling key repeat for subtitle navigation.
