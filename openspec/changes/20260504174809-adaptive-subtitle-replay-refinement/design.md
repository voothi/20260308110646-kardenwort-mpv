# Design: Adaptive Subtitle Replay

**ID**: 20260504174809-adaptive-subtitle-replay-refinement
**Change**: 20260504174809-adaptive-subtitle-replay-refinement

## Architectural Components

### 1. Adaptive Segment Engine
The `cmd_replay_sub` function will be updated to compute `FSM.REPLAY_START` and `FSM.REPLAY_END` dynamically based on the current `time_pos` and `Options.replay_ms`.

**Logic**:
```lua
local replay_start = time_pos - Options.replay_ms/1000
local replay_end = time_pos
```

### 2. Multi-Iteration Controller
We will use a new FSM state `FSM.REPLAY_REMAINING` to track how many more times we need to loop.

**Logic in `tick_scheduled_replay`**:
```lua
if time_pos >= FSM.SCHEDULED_REPLAY_END - Options.pause_padding then
    if FSM.REPLAY_REMAINING > 1 then
        FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
        mp.commandv("seek", FSM.SCHEDULED_REPLAY_START, "absolute+exact")
        return true
    else
        FSM.REPLAY_REMAINING = 0
        -- ... normal finish ...
    end
end
```

### 3. Ghosting Sync (Sticky Hold Expiry)
To solve the "stuck in HOLDING" problem, we introduce a temporal leash for the forced state.

**In `cmd_replay_sub`**:
```lua
if was_holding_space then
    FSM.SPACEBAR = "HOLDING"
    FSM.GHOST_HOLD_EXPIRY = mp.get_time() + 2.0 -- 2 second safety window
end
```

**In `master_tick`**:
```lua
if FSM.SPACEBAR == "HOLDING" and FSM.GHOST_HOLD_EXPIRY and mp.get_time() > FSM.GHOST_HOLD_EXPIRY then
    FSM.SPACEBAR = "IDLE"
    FSM.GHOST_HOLD_EXPIRY = nil
    Diagnostic.debug("Ghost Hold Expired")
end
```

**In `cmd_smart_space` (down event)**:
```lua
if table.event == "down" then
    FSM.GHOST_HOLD_EXPIRY = nil -- User is physically holding, clear expiry
    -- ... normal logic ...
end
```

## State Machine Extensions
| State | Type | Description |
|---|---|---|
| `FSM.GHOST_HOLD_EXPIRY` | number | Timestamp when the forced "HOLDING" state should expire. |
| `FSM.REPLAY_REMAINING` | number | Counter for remaining iterations of the current replay/loop. |
| `Options.replay_ms` | number | Fixed window size for adaptive replay (0 = whole sub). |
| `Options.replay_count` | number | Number of iterations for the replay command. |
