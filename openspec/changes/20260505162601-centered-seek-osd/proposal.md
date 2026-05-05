## Why

Users currently lack clear visual feedback for time-based seeking (LEFT/RIGHT, Shift+A/Shift+D), making it difficult to judge the skip distance without looking at the timeline. Standard mpv OSD is often small or disabled. A centered, minimalist feedback improves focus and provides a premium, "wow" interaction experience.

## What Changes

- **New Options**: Introduce `seek_time_delta` (amount to seek) and `seek_osd_duration` (how long to show the message).
- **Script-Driven Seeking**: Implement `lls-seek_time_forward` and `lls-seek_time_backward` in `lls_core.lua` to handle both the seek operation and the custom OSD.
- **Centered OSD**: Display a large, centered message (e.g., `+2` or `-2`) using `{\an5}` alignment.
- **Key Binding Updates**: Remap `LEFT`, `RIGHT`, `Shift+A`, and `Shift+D` in `input.conf` to use the new script bindings.

## Capabilities

### New Capabilities
- `centered-seek-feedback`: Implementation of high-visibility, centered OSD feedback for relative time seeking.

### Modified Capabilities
- `layout-agnostic-seeking`: Expand requirement to include script-mediated time seeking with visual confirmation.
- `centralized-script-options`: Register new behavioral parameters for seek delta and OSD duration.

## Impact

- **lls_core.lua**: Core logic for the new seek commands and OSD rendering.
- **input.conf**: Shift from native `seek` to `script-binding`.
- **mpv.conf**: Exposure of new user-tunable parameters.
