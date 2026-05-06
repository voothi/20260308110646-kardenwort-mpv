## Context

During the implementation of centered-seek-osd (2f6d85a), the Shift+A/D keybindings were migrated from native mpv `seek` commands (which auto-repeat on hold) to Lua script bindings (which require explicit `{repeatable = true}` flag for repeat behavior). This oversight broke the key repeat behavior users relied on for continuous seeking while holding the key.

## Goals / Non-Goals

**Goals:**
- Restore hold-to-repeat behavior for Shift+A/D time-based seeking
- Preserve the custom OSD feedback introduced by centered-seek-osd
- Ensure the fix maintains compatibility with the accumulator logic

**Non-Goals:**
- Modifying any other key bindings or seeking mechanisms
- Changing the OSD behavior or styling
- Adding new features beyond restoration

## Decisions

- **Decision 1: Add `{repeatable = true}` flag**
  - **Rationale**: In mpv's Lua API, `mp.add_key_binding` without this flag only fires on keydown. With the flag, it fires on both keydown and repeat events (which mpv generates automatically when a key is held).
  - **Alternative**: Use `{complex = true}` and manually handle repeat events. **Rejection**: Unnecessary complexity; the simple flag is sufficient and matches the design of similar bindings.

- **Decision 2: No changes to `cmd_seek_time` function**
  - **Rationale**: The function already correctly handles multiple rapid invocations via the accumulator state machine. No code logic changes are needed.
  - **Consequence**: Repeat events will trigger the same function behavior that single presses do, which is exactly correct.

## Risks / Trade-offs

- **[Risk]** Accidental excessive seeking if user holds key too long. → **Mitigation**: None needed; this is the intended behavior and matches native mpv seek commands.
- **[Risk]** State confusion from rapid repeat events. → **Mitigation**: The accumulator state machine already handles arbitrary repeat rates; no risk.

## Implementation Approach

1. Locate the two `mp.add_key_binding` calls for `lls-seek_time_forward` and `lls-seek_time_backward` in `scripts/lls_core.lua` (lines 7692-7693)
2. Add `{repeatable = true}` as the fourth parameter to each call
3. Verify behavior by holding Shift+A/D in the player and confirming continuous seeking

## Success Criteria

- Holding Shift+A continuously seeks backward with OSD updates on each repeat
- Holding Shift+D continuously seeks forward with OSD updates on each repeat
- OSD accumulator updates correctly during hold (reflecting YouTube-style cumulative behavior)
- No regression in other functionality (single presses still work, OSD styling unchanged)
