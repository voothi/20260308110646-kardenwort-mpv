## Context

In the Kardenwort-mpv immersion engine, the `Autopause` system monitors the playhead position relative to subtitle boundaries. In `PHRASE` mode, these boundaries include an "audio padding" buffer (default 200ms). When a user navigates between subtitles using `Shift+a` (Previous) or `Shift+d` (Next), the engine jumps to the start of the target subtitle's padded boundary.

However, if multiple subtitles have overlapping padded boundaries (due to high padding or tight gaps), the engine's "Magnetic Snapping" logic or the autopause trigger may cause playback to stall or "jerk" as it transits through these overlapping zones.

## Goals / Non-Goals

**Goals:**
- Implement "Fluid Navigation": Suppress all autopause triggers and boundary-enforced stops during manual subtitle jumps (`Shift+a/d`).
- Mode-Switching during Jumps: Treat manual jumps as "Pseudo-MOVIE" transitions to ensure seamless audio handover.
- Standardize Test Constants: Update the regression suite to use 200ms padding instead of the non-default 1000ms.
- Fix LlsProbe resolution: Ensure the test harness can inspect Lua table methods.

**Non-Goals:**
- Changing the default `PHRASE` mode behavior during normal (non-navigational) playback.
- Altering the core OSD rendering logic.

## Decisions

1. **Rewind Inhibit Sentinel**: Introduce `FSM.TIMESEEK_INHIBIT_UNTIL`.
    - On **Backward Seek** (`delta < 0`): Set to `math.max(sentinel, current_pos)` in `cmd_seek_time`.
    - On **Forward Seek** (`delta > 0`): Cleared to `nil`.
2. **Autopause Suppression**: In `tick_autopause`, return immediately if `time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL`.
3. **Jerk-Back Suppression**: Gate the Phrase overlap jerk-back logic in `master_tick` with `not FSM.TIMESEEK_INHIBIT_UNTIL`.
4. **Sentinel Clearing**: Clear the inhibit in `master_tick` only when `time_pos > FSM.TIMESEEK_INHIBIT_UNTIL` (strict greater than).
5. **IPC Instrumentation**: Register `lls-test-seek-time` script message and update `LlsProbe._snapshot` to expose the new sentinel fields.
6. **LlsProbe Fallback**: Modify `_func_body` in the IPC harness to check `LlsProbe[name]` if `_G[name]` fails.
7. **Test Alignment**: Update `test_20260509134903_timeseek_transit.py` to reflect 200ms padding boundaries.

## Risks / Trade-offs

- **Risk**: Skipping autopause might cause the user to miss the exact start point if they are spamming keys. 
- **Mitigation**: The inhibition is only active during the `down` state or a very short settle period.
