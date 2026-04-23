## Why

This change formalizes the Dual Subtitle Positional Control & Layout Agnosticism introduced in Release v1.2.12. As users encounter complex, multi-line subtitles that frequently overlap, the need for independent manual control over both primary and secondary tracks became evident. This update also continues the project's goal of keyboard layout agnosticism, ensuring that critical adjustments can be made without switching system languages.

## What Changes

- Implementation of **Independent Secondary Subtitle Positioning**: New keybindings (`Shift+R` and `Shift+T`) allow the user to adjust the vertical position of the secondary (translation) track independently of the primary track.
- Implementation of **Layout-Agnostic Primary Positioning**: Standard mpv positioning keys (`r` and `t`) are now mirrored to their Russian layout counterparts (`к` and `е`).
- Synchronization with Drum Mode: Manual positional adjustments are maintained across "Drum Mode" state transitions, ensuring that context lines align correctly with the user's custom base positioning.

## Capabilities

### New Capabilities
- `independent-sub-positioning`: The ability to manually tune the vertical alignment of secondary subtitle tracks to prevent visual collisions with primary dialogue or context lines.
- `positioning-layout-agnosticism`: A configuration pattern where subtitle adjustment controls are mapped symmetrically across multiple keyboard layouts.

### Modified Capabilities
- None (User control refinement).

## Impact

- **Visual Clarity**: Users can surgically resolve subtitle overlaps in dense dialogue files.
- **Workflow Efficiency**: Eliminates the friction of switching keyboard layouts to perform minor positional adjustments during study.
- **Consistency**: Manual positions serve as the baseline for dynamic Drum Mode rendering, ensuring a predictable visual experience.
