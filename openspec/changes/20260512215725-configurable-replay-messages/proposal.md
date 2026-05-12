## Why

On-screen display (OSD) feedback for the replay functionality is currently hardcoded in `main.lua`. This prevents users from customizing the message content, translating it, or adjusting the level of detail provided during study sessions. 

## What Changes

- **Externalized Templates**: Replay messages will be moved from hardcoded strings to configurable script-options in `mpv.conf`.
- **Placeholder Support**: Support for dynamic placeholders (`%m` for milliseconds, `%c` for iteration count) will be implemented to maintain parity with the existing `seek_msg_format` system.
- **Mode-Specific Formatting**: Separate templates for Autopause ON and OFF modes to allow distinct phrasing (e.g., "Flashback" vs "Repeating").

## Capabilities

### New Capabilities
- `configurable-replay-feedback`: Logic for parsing and rendering parameterized replay OSD messages using user-defined templates.

### Modified Capabilities
- `centralized-script-options`: Add `replay_msg_format` and `replay_on_msg_format` to the canonical options list.
- `subtitle-replay`: Transition internal message triggering to the new templating engine.

## Impact

- `scripts/kardenwort/main.lua`: Modification of `Options` table and `cmd_replay_sub` function.
- `mpv.conf`: Addition of new configuration keys.
- `tests/acceptance/`: Existing tests that verify OSD output may need to be updated or will benefit from more precise assertions.
