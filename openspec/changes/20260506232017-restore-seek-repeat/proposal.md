# OpenSpec: Restore Seek Repeat Behavior

**ID**: 20260506232017-restore-seek-repeat
**ZID**: 20260506232017
**Status**: Design Phase

## Objective

Restore continuous hold-to-repeat behavior for Shift+A/D time-based seeking that was broken when transitioning from native mpv seek commands to Lua script bindings in the centered-seek-osd implementation.

## What Changes

### Issue
Commit `2f6d85a` (20260505163204) replaced native mpv `seek ±2 exact` commands with Lua `script-binding` handlers to enable custom OSD feedback. However, the Lua bindings were registered without `{repeatable = true}` flag, causing them to fire only once per keypress instead of repeatedly when held.

**Before** (working):
```
A seek -2 exact      # mpv's native seek repeats on hold
D seek  2 exact
```

**After** (broken):
```
A script-binding lls-seek_time_backward  # Lua binding, repeats disabled
D script-binding lls-seek_time_forward
```

### Solution
Add `{repeatable = true}` to the two Lua key binding registrations in `scripts/lls_core.lua` (lines 7692-7693) to restore mpv's automatic repeat-on-hold behavior for Lua script bindings.

**Fixed**:
```lua
mp.add_key_binding(nil, "lls-seek_time_forward", function() cmd_seek_time(1) end, {repeatable = true})
mp.add_key_binding(nil, "lls-seek_time_backward", function() cmd_seek_time(-1) end, {repeatable = true})
```

## Technical Details

- **Files Modified**: `scripts/lls_core.lua`
- **Lines Changed**: 7692-7693 (+2 additions per line)
- **Logic**: The `cmd_seek_time` function already handles repeated invocations correctly via the accumulator logic. The issue was purely in key binding registration flags.
- **Compatibility**: `{repeatable = true}` is standard in mpv Lua API and fully compatible with the existing script architecture.
