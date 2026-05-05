## Why

Users currently lack clear visual feedback for time-based seeking (LEFT/RIGHT, Shift+A/Shift+D), making it difficult to judge the skip distance without looking at the timeline. Standard mpv OSD is often small or disabled. A centered, minimalist feedback improves focus and provides a premium, "wow" interaction experience.

## What Changes

- **New Options**: Introduce `seek_time_delta` (amount to seek), `seek_osd_duration`, and a full set of styling parameters (`seek_font_name`, `seek_font_size`, `seek_color`, etc.).
- **Directional OSD**: Display messages on the left (`{\an4}`) for backward seeks and on the right (`{\an6}`) for forward seeks.
- **Script-Driven Seeking**: Implement `lls-seek_time_forward` and `lls-seek_time_backward` in `lls_core.lua` to handle the seek operation, directional logic, and custom OSD styling.
- **Key Binding Updates**: Remap `LEFT`, `RIGHT`, `Shift+A`, and `Shift+D` in `input.conf` to use the new script bindings.

## Capabilities

### New Capabilities
- `directional-seek-feedback`: Implementation of high-visibility, directional OSD feedback (Left/Right) with dedicated styling parameters.

### Modified Capabilities
- `layout-agnostic-seeking`: Expand requirement to include script-mediated time seeking with visual confirmation.
- `centralized-script-options`: Register new behavioral parameters for seek delta and OSD duration.

## Impact

- **lls_core.lua**: Core logic for the new seek commands and OSD rendering.
- **input.conf**: Shift from native `seek` to `script-binding`.
- **mpv.conf**: Exposure of new user-tunable parameters.
