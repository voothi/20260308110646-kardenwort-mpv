# Specification: Unified Adaptive Replay (Flashback)

**ID**: subtitle-replay-refinement
**Scope**: Unified Replay System (`s` key)
**Status**: FINAL
**ZID**: 20260504184237

## Functional Requirements

### 1. Subtitle-Independent Fixed-Window Replay
- **REQ-1.1**: The `S` key SHALL trigger a replay anchored to the current playback position (`T_now`).
- **REQ-1.2**: The replay segment SHALL be calculated as `[T_now - Options.replay_ms, T_now]`.
- **REQ-1.3**: Subtitle boundaries SHALL be ignored during segment calculation to allow for cross-subtitle phrase repetition.
- **REQ-1.4**: The `tick_autopause` controller SHALL be silenced during the replay to prevent interruptions at intermediate subtitle boundaries.

### 2. Unified Multi-Iteration Controller
- **REQ-2.1**: The script SHALL support replaying the segment `N` times as defined by `Options.replay_count` in BOTH `Autopause ON` and `Autopause OFF` modes.
- **REQ-2.2**: After `N` iterations, the replay SHALL be automatically deactivated.
- **REQ-2.3**: In `Autopause ON` mode, the script SHALL check `Options.replay_autostop`:
    - If `yes`, the player SHALL pause at the end of the iterations.
    - If `no`, the player SHALL continue until the end of the current subtitle line (standard Autopause).
- **REQ-2.4**: In `Autopause OFF` mode, the player SHALL always continue playback forward without interruption.

### 3. Hardware Ghosting Resistance (Sticky Hold Recovery)
- **REQ-3.1**: When `s` is pressed, if a "Space UP" event occurred within the last 300ms, the script SHALL force `FSM.SPACEBAR` to `"HOLDING"`.
- **REQ-3.2**: This forced state SHALL have a 2-second temporal leash (`FSM.GHOST_HOLD_EXPIRY`).
- **REQ-3.3**: If no physical "Space DOWN" is received within the leash, the state SHALL automatically revert to `"IDLE"`.

### 4. User Experience (OSD)
- **REQ-4.1**: OSD feedback SHALL be concise (e.g., "Replay: 2000ms").
- **REQ-4.2**: Mode transitions and iteration finishes SHALL be silent in `Autopause OFF` to maintain streaming immersion.
