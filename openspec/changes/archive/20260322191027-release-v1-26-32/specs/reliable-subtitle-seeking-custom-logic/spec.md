# Spec: Reliable Subtitle Seeking (Custom Logic)

## Context
Native `sub-seek` can be unreliable when paused near subtitle boundaries.

## Requirements
- Implement `cmd_dw_seek_delta(delta)` to handle subtitle jumps.
- Use the internal `Tracks.pri.subs` table to find the target subtitle index based on current time and delta.
- Execute the jump using `mp.commandv("seek", timestamp, "absolute", "exact")`.
- This logic must replace the default `a`/`d` bindings while the Drum Window is active.

## Verification
- Pause the video near the end of a subtitle (simulating an autopause).
- Press `d`.
- Verify the player immediately jumps to the start of the next subtitle on the first press.
- Repeat for `a` and verify backward navigation.
