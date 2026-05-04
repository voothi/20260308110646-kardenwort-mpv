# Design: Unified Adaptive Replay (Flashback)

**ID**: 20260504174809-adaptive-subtitle-replay-refinement
**Change**: 20260504174809-adaptive-subtitle-replay-refinement
**Status**: FINAL
**ZID**: 20260504184237

## Architectural Components

### 1. Flashback Engine (`cmd_replay_sub`)
The replay logic is now decoupled from the subtitle table. It uses a relative offset from the current `time_pos`.

**Logic**:
```lua
local replay_start = math.max(0, time_pos - Options.replay_ms/1000)
local replay_end = time_pos
```

### 2. Unified Iteration Logic
The `FSM.REPLAY_REMAINING` counter is shared by both `tick_scheduled_replay` (Autopause ON) and `tick_loop` (Autopause OFF).

- **Autopause ON**: Pauses at the end of the final iteration ONLY if `Options.replay_autostop` is true. Otherwise, it continues to the next standard subtitle boundary.
- **Autopause OFF**: Disables `LOOP_MODE` at the end of the final iteration and continues playback forward.

### 3. Autopause Silence
To ensure segments can span subtitle boundaries, `tick_autopause` returns early if `FSM.SCHEDULED_REPLAY_START` or `FSM.LOOP_MODE == "ON"` is active.

### 4. Temporal Leash (Ghosting Fix)
Forced "HOLDING" state is validated against a 2-second expiry timestamp in `master_tick`. Physical `down` events reset this leash.

## Configuration (mpv.conf)
```ini
# Unified Replay (Flashback)
lls-replay_ms=2000
lls-replay_count=1
lls-replay_autostop=yes
```
