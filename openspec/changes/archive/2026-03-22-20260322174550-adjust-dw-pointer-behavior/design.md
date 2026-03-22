# Design: Adjust Drum Window Pointer Behavior

## Architecture Overview
The Drum Window logic resides primarily in `scripts/lls_core.lua`. The state is managed in the `FSM` table, specifically using `DW_CURSOR_LINE` and `DW_CURSOR_WORD`. The rendering is handled by the `draw_dw` function, which uses `ass-events` to draw the UI.

## Technical Details

### 1. Pointer Inactive State
We will use `-1` as the value for `FSM.DW_CURSOR_WORD` to indicate that no word is currently highlighted. The rendering logic in `draw_dw` already implicitly supports this, as it compares the loop index `j` (which starts at 1) with `FSM.DW_CURSOR_WORD`.

### 2. Initialization & Reset Logic
The pointer should be set to `-1` in the following scenarios:
- **Window Open**: In `cmd_toggle_drum_window`, when the window is first opened (`FSM.DRUM_WINDOW == "OFF" -> "DOCKED"`).
- **Manual Scroll**: In `cmd_dw_scroll` (triggered by mouse wheel or Ctrl+UP/DOWN).
- **Subtitle Seeking**: In the `a` and `d` key bindings within `manage_dw_bindings`.

### 3. Activation Logic
The pointer should be activated (shown) when the user interacts with the arrow keys:
- **Left/Right Arrows**: `cmd_dw_word_move` already handles the `-1` state by initializing `DW_CURSOR_WORD` to `1` or the last word index of the line.
- **Up/Down Arrows**: `cmd_dw_line_move` currently resets `DW_CURSOR_WORD` to `1` on every move. This behavior is acceptable as it immediately shows the pointer on the new line.

### 4. Key Binding Updates
The `a` and `d` keys (and their Russian equivalents `ф` and `в`) in `manage_dw_bindings` need to be updated to set `FSM.DW_CURSOR_WORD = -1` instead of `1`.

## Impact Assessment
- **Copy Logic**: The `cmd_dw_copy` function (and potentially others) will need to handle `DW_CURSOR_WORD == -1` to ensure it copies the whole line/context when no word is selected. *Self-correction: I should verify the copy logic.*
- **Mouse Selection**: Clicking a word will set `DW_CURSOR_WORD` to a valid index, which will naturally "wake up" the pointer.

## File Modifications
- `scripts/lls_core.lua`:
    - `cmd_toggle_drum_window`
    - `cmd_dw_scroll`
    - `manage_dw_bindings`
