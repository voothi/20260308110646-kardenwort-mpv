# Design: Fix Drum Window Navigation Double-Tap

## Architecture
The fix will introduce a more robust seeking mechanism specifically for the Drum Window. It will leverage the pre-loaded `Tracks.pri.subs` table which is guaranteed to be present while the window is open.

## Technical Implementation
1.  **New Utility Function**: Implement `cmd_dw_seek_delta(direction)`:
    -   Get current `time_pos`.
    -   Get current subtitle index via `get_center_index(subs, time_pos)`.
    -   Calculate `target_idx = current_idx + direction`.
    -   Seek to `subs[target_idx].start_time` using `absolute+exact`.
    -   Update `FSM` states (`DW_FOLLOW_PLAYER = true`, reset pointers).
2.  **Update Bindings**:
    -   Update `a` (`dw-seek-back`) to call `cmd_dw_seek_delta(-1)`.
    -   Update `d` (`dw-seek-fwd`) to call `cmd_dw_seek_delta(1)`.
    -   Do the same for Russian equivalents (`ф`, `в`).

## Impact Assessment
-   **lls_core.lua**: Replaces four `mp.command("sub-seek ...")` calls with a more reliable local function call.
-   **UX**: Snappier navigation when paused.
