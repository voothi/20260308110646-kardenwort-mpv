## Context

Kardenwort-mpv relies on highly specific hotkey interactions for its language acquisition tools. The replay (`s` / `ы`) functionality must seamlessly support two workflows: "Streaming Mode" (Autopause OFF) where the user wants to quickly loop difficult segments, and "Semi-Automatic Mode" (Autopause ON with Spacebar held) where the user wants one-shot replays without breaking the continuous flow of playback. A critical issue emerged where the OS/mpv keyboard matrix drops the Space key signal when `s` is pressed concurrently, resulting in a ghost `up` event that erroneously triggers the autopause at the end of the replay.

## Goals / Non-Goals

**Goals:**
- Implement a dual-mode behavior for the `s` hotkey based on the `FSM.AUTOPAUSE` state.
- Prevent abrupt backward seeks if the user presses `s` mid-subtitle; delay the seek until the end of the subtitle.
- Completely defeat the OS/mpv hardware ghosting issue when `s` is pressed while the Space key is held down.
- Ensure the Space key functions as an override to break out of persistent loops.

**Non-Goals:**
- Creating new hotkeys for looping vs single-replay. Everything must be unified under the `s` key.
- Rewriting the core mpv input driver to fix ghosting at the source. The fix must be handled locally within the Lua FSM.

## Decisions

1. **Dual-Mode Replay Strategy**: In Autopause OFF mode, `s` toggles persistent looping (`FSM.LOOP_MODE = "ON"`). In Autopause ON mode, `s` triggers a one-shot replay via `FSM.SCHEDULED_REPLAY_START`.
2. **Arming Guards and Scheduling**: Instead of seeking immediately upon keypress, we register the replay intent. The execution is deferred to `tick_loop` or `tick_scheduled_replay` which trigger only when `time_pos >= sub_end - padding`. This ensures the current playback finishes naturally.
3. **Ghosting Defeat via Sticky Hold**: When `s` is pressed, the script evaluates if Space is held or was *just* released within 300ms. If true, the script forcefully rewrites `FSM.SPACEBAR = "HOLDING"`. This defeats the fake `up` event and guarantees the player will "go over the border" without pausing.
4. **Spacebar Loop Override**: If `LOOP_MODE` is active and the boundary is reached, checking `FSM.SPACEBAR == "HOLDING"` disables the loop, allowing the player to repeat one last time and continue.

## Risks / Trade-offs

- **Risk**: Sticky Hold forces the script to ignore a true Space release if it coincides perfectly with an `s` press.
  - *Mitigation*: The user only needs to tap Space once to reset the state if they genuinely intended to pause immediately after initiating a replay while holding Space. In a continuous "semi-automatic" workflow, this is a minor and highly acceptable trade-off.
