# Specification: Adaptive Subtitle Replay

**ID**: subtitle-replay-refinement
**Scope**: Subtitle Replay (`s` key)
**Status**: DRAFT

## Functional Requirements

### 1. Adaptive Segment Calculation
- **REQ-1.1**: The script SHALL calculate the replay start point based strictly on `Options.replay_ms` relative to the time of the keypress (`T_now`).
- **REQ-1.2**: The replay start point SHALL be `T_now - Options.replay_ms/1000`.
- **REQ-1.3**: The replay end point SHALL be `T_now`.
- **REQ-1.4**: Subtitle boundaries SHALL be ignored for the purpose of calculating the replay segment.

### 2. Multi-Iteration Support
- **REQ-2.1**: The script SHALL support replaying the segment `N` times as defined by `Options.replay_count` in BOTH `Autopause ON` and `Autopause OFF` modes.
- **REQ-2.2**: After `N` iterations, the loop/replay SHALL be automatically deactivated, and the player SHALL either pause (Autopause ON) or continue (Autopause OFF).

### 3. Ghosting Resistance (Sticky Hold Recovery)
- **REQ-3.1**: When `s` is pressed while Space is up but was released within 300ms, the script SHALL force `FSM.SPACEBAR` to `"HOLDING"`.
- **REQ-3.2**: This forced `"HOLDING"` state SHALL expire after 2 seconds of playback.
- **REQ-3.3**: Upon expiry, the state SHALL revert to `"IDLE"`, allowing normal `Autopause` behavior to resume if the user has physically released the key.
- **REQ-3.4**: A physical "Space DOWN" event SHALL cancel the expiry timer.

### 4. Mode-Aware Behavior
- **REQ-4.1**: In `Autopause OFF`, the `s` key SHALL toggle a persistent loop.
- **REQ-4.2**: In `Autopause ON`, the `s` key SHALL schedule a one-shot (or multi-iteration) replay.
