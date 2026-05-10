## Why

The current autopause logic for rewind operations is overly complex. When rewinding via `s` (replay-subtitle) or `Shift+a/d` (seek time backward/forward), the system should simply turn off autopause temporarily for the duration of the rewind. This simplification improves user experience and reduces code complexity.

## What Changes

- **New behavior**: When `Shift+a` or `Shift+d` is pressed to seek backward/forward and the seek crosses subtitle boundaries, autopause will be temporarily disabled for the seek duration
- **No change for replay**: When `s` is pressed to replay a subtitle, autopause continues to work normally (stays within same subtitle)
- **Simplification**: Remove complex autopause state management logic during rewind operations
- **State restoration**: Autopause state will be restored after the seek duration elapses

## Capabilities

### New Capabilities
- `rewind-autopause-suppression`: Simplified autopause behavior that temporarily disables autopause during seek operations (Shift+a/d) that cross subtitle boundaries, for the duration of the seek

### Modified Capabilities
- `karaoke-autopause`: The existing autopause capability will be modified to support temporary suppression during rewind operations without changing its core pause-at-phrase/word behavior

## Impact

- **Affected code**: `scripts/lls_core.lua` (main script handling keybindings and autopause logic)
- **Affected bindings**: `input.conf` bindings for `Shift+a`, `Shift+d` (s key unchanged)
- **Dependencies**: None - this is a simplification of existing behavior
