# Implementation Tasks

## Task 1: Add `{repeatable = true}` to forward seek binding
**Status**: Pending
**ZID**: 20260506232017

Edit `scripts/lls_core.lua` line 7692:

```lua
-- Before:
mp.add_key_binding(nil, "lls-seek_time_forward", function() cmd_seek_time(1) end)

-- After:
mp.add_key_binding(nil, "lls-seek_time_forward", function() cmd_seek_time(1) end, {repeatable = true})
```

**Verification**: Line contains `, {repeatable = true}` before closing parenthesis.

---

## Task 2: Add `{repeatable = true}` to backward seek binding
**Status**: Pending
**ZID**: 20260506232017

Edit `scripts/lls_core.lua` line 7693:

```lua
-- Before:
mp.add_key_binding(nil, "lls-seek_time_backward", function() cmd_seek_time(-1) end)

-- After:
mp.add_key_binding(nil, "lls-seek_time_backward", function() cmd_seek_time(-1) end, {repeatable = true})
```

**Verification**: Line contains `, {repeatable = true}` before closing parenthesis.

---

## Task 3: Test hold-to-repeat behavior
**Status**: Pending
**ZID**: 20260506232017

1. Start the player with a video loaded
2. Hold down Shift+A (or A key) for 2-3 seconds
3. Confirm continuous seeking backward occurs (not just a single jump)
4. Confirm OSD message updates appear for each repeat with cumulative totals
5. Release key and confirm seeking stops
6. Repeat with Shift+D (or D key) for forward seeking

**Success**: Continuous seeking with live OSD updates on both forward and backward directions.

---

## Task 4: Verify no regressions
**Status**: Pending
**ZID**: 20260506232017

1. Single tap Shift+A/D - should seek once
2. LEFT/RIGHT arrow keys - should work normally (different binding)
3. Other navigation (lls-seek_prev/next) - should work normally
4. OSD styling and configuration - should be unchanged

**Success**: All other bindings and features work as before.
