## 1. Hotkey and FSM Logic

- [x] 1.1 Update `input.conf` to clean up double/triple bindings for the `s` and `ы` keys, ensuring they map uniquely to a single handler.
- [x] 1.2 Modify `cmd_replay_sub` to act as a toggle for `LOOP_MODE` when Autopause is OFF, and to schedule a single replay when Autopause is ON.
- [x] 1.3 Add a smart `LOOP_ARMED` guard that requires playback to be inside the subtitle before triggering a loop seek back, preventing immediate jumps.
- [x] 1.4 Add `tick_scheduled_replay` to execute the backward seek at the end of the subtitle for Autopause ON mode.

## 2. Hardware Ghosting Workaround

- [x] 2.1 Add `space_up_time` tracking to the `FSM` state in `cmd_smart_space` to record exactly when the Space key was released.
- [x] 2.2 Implement "Sticky Hold" check in `cmd_replay_sub` to detect fake `up` events that occurred within 300ms of pressing `s`.
- [x] 2.3 Force `FSM.SPACEBAR = "HOLDING"` if ghosting is detected, completely bypassing `tick_autopause` and guaranteeing continuous playback.

## 3. Loop Mode Overrides

- [x] 3.1 Implement an override in `tick_loop` that checks if `FSM.SPACEBAR == "HOLDING"`.
- [x] 3.2 If Space is held during a loop boundary, automatically turn off `LOOP_MODE` so the system repeats one last time and seamlessly continues into the next subtitle.
