## Technical Design: Selection Persistence & Tooltip Targeting Stability

### Selection Stability in Standard (Follow) Mode
To resolve the "stretching" issue where selections would expand as the video plays, the implementation decouples the `DW_CURSOR_LINE` from the playback active subtitle when a selection is present.

- **Selective Update Logic**: In `tick_dw` and `cmd_dw_seek_delta`, the `FSM.DW_CURSOR_LINE` update is now conditional:
    - `if FSM.DW_ANCHOR_LINE == -1 then FSM.DW_CURSOR_LINE = active_idx end`
- **Result**: If an anchor point exists (the user has started a selection), the yellow focus point remains fixed to the text line, even as the video's active (white) line advances.

### Playback-Aware Tooltip Targeting
To ensure the tooltip follows the current audio while listening and remains stable after an autopause, we've implemented a playback-state-aware mode toggle.

- **Pause Observer**: A property observer on the `pause` property sets `FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"` whenever `pause` becomes `false`.
- **Targeting Logic (Ticker)**:
    - **During Playback**: Always follow `DW_ACTIVE_LINE`.
    - **During Pause (including Autopause)**: If `TARGET_MODE` is `"ACTIVE"`, stay on `DW_ACTIVE_LINE`. If interaction occurs (arrows, mouse), switch `TARGET_MODE` to `"CURSOR"` to follow the selection.
- **Benefit**: This eliminates the "noise" of the tooltip jumping back to a stale selection cursor upon every autopause.

### Selection Cleanup & Phantom Prevention
To maintain a clean interface in Standard Mode, "phantom" single-word highlights are cleared during deliberate seeking actions.

- **Range Persistence**: Multi-word selections (`ANCHOR_LINE ~= -1`) are always preserved during manual navigation.
- **Single-Word Reset**: If no range exists, `DW_CURSOR_WORD` is reset to `-1` during `a/d` seeks or double-click seeks.
- **Track-Change Reset**: All selection states (`ANCHOR`, `CURSOR`) and tooltip targeting modes are reset globally upon any subtitle track change to prevent OOB (Out-of-Bounds) index crashes and stale context access.

### Manual Navigation Fixes
- `cmd_dw_seek_delta`: Consolidated redundant `BOOK_MODE` checks and implemented conditional cursor updates and word resets.
- `cmd_dw_double_click`: Cleaned up to ensure that seeking via double-click also resets the selection state completely to avoid leaving phantom pointers on the new line.
