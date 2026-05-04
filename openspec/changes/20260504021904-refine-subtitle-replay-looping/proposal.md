## Why

The user requires a robust, layout-agnostic, dual-mode subtitle replay and looping system for `kardenwort-mpv`. Previously, replay behavior lacked separation between the "streaming" mode (Autopause OFF) and "controlled" mode (Autopause ON). Furthermore, hardware keyboard ghosting limitations on Windows caused the spacebar "hold" state to drop when pressing the replay hotkey (`s` / `ы`), resulting in unintended pauses during semi-automatic continuous playback.

## What Changes

- **Dual-Mode Replay Hotkey (`s` / `ы`)**: Implement mode-aware logic where `s` toggles persistent Loop Mode when Autopause is OFF, and acts as a one-shot Manual Replay when Autopause is ON.
- **Smart Replay Delay (Arming Guard & Scheduling)**: Prevent abrupt playback interruptions. If `s` is pressed mid-subtitle, the system waits for playback to reach the end of the subtitle before seeking back.
- **Hardware Ghosting Workaround (Sticky Hold)**: Defeat OS/mpv key signal dropping. If an `up` event for Space is detected immediately (< 300ms) after pressing `s`, the system restores the `SPACEBAR = "HOLDING"` state, ensuring continuous semi-automatic playback is not interrupted.
- **Loop Override**: In Autopause OFF mode, holding Space while a loop reaches its boundary breaks the loop, repeating once and then continuing to the next subtitle.

## Capabilities

### New Capabilities
- `subtitle-replay-loop`: Defines the dual-mode interaction schema, execution boundaries, and hardware ghosting workarounds for the `s` / `ы` replay bindings.

### Modified Capabilities
<!-- None -->

## Impact

- `scripts/lls_core.lua`: Significant changes to the `master_tick`, `tick_loop`, `tick_autopause`, and the introduction of `tick_scheduled_replay`. Spacebar event tracking expanded to defeat hardware ghosting.
- `input.conf`: Removed double/triple bindings for replay collisions.

## References

- **Initial Commit**: `3318c953f763099327f21b4f5401d3373c1c7107`
- **Dialogue Anchors**:
  - `20260504003137`: Initial replay function request.
  - `20260504003516`: Hotkey assignment to `s`.
  - `20260504004117`: Request for manual control in Autopause ON.
  - `20260504005552`: Differentiation between persistent loop and manual mode.
  - `20260504010222`: Navigation freedom during loop.
  - `20260504010554`: Non-interrupted current playback.
  - `20260504011009`: Parity between OFF/ON modes.
  - `20260504011801`: Conservative behavior in Autopause ON.
  - `20260504012741`: Prevention of mid-subtitle rewinds.
  - `20260504014731`: Introduction of semi-automatic mode requirements.
  - `20260504015815`: Identification of spacebar release issues.
  - `20260504021350`: Ghost release hypothesis and solution path.
