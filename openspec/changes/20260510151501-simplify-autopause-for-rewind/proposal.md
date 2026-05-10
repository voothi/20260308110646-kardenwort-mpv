## Why

The current autopause logic for rewind operations is overly complex. When rewinding via `s` (replay-subtitle) or `Shift+a/d` (seek time backward/forward), the system should simply turn off autopause temporarily for the duration of the rewind. This simplification improves user experience and reduces code complexity.

## What Changes

- **New behavior**: When `s` is pressed to replay a subtitle, autopause will be temporarily disabled for the rewound duration
- **New behavior**: When `Shift+a` or `Shift+d` is pressed to seek backward/forward, autopause will be temporarily disabled for the rewound duration
- **Simplification**: Remove complex autopause state management logic during rewind operations
- **State restoration**: Autopause state will be restored after the rewound duration elapses

## Capabilities

### New Capabilities
- `rewind-autopause-suppression`: Simplified autopause behavior that temporarily disables autopause during rewind operations (s, Shift+a/d) for the duration of the rewind

### Modified Capabilities
- `karaoke-autopause`: The existing autopause capability will be modified to support temporary suppression during rewind operations without changing its core pause-at-phrase/word behavior

## Impact

- **Affected code**: `scripts/lls_core.lua` (main script handling keybindings and autopause logic)
- **Affected bindings**: `input.conf` bindings for `s`, `Shift+a`, `Shift+d`
- **Dependencies**: None - this is a simplification of existing behavior
