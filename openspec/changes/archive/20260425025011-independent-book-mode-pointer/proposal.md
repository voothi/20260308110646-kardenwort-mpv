## Why

The current manual navigation logic in Book Mode occasionally resets or clears the yellow pointer (word focus) during seeking operations. Formalizing the independence of the yellow pointer ensures a stable "reading" experience where the user's focus point remains stationary even as the video seeks or playback progresses.

## What Changes

- **Pointer Independence**: In Book Mode ON, the yellow pointer (DW_CURSOR_LINE/WORD) is decoupled from the white active subtitle (DW_ACTIVE_LINE).
- **Seek Behavior**: Manual seeking via `a`/`d` will no longer update or clear the yellow pointer in Book Mode ON.
- **Persistence**: The yellow pointer will remain in its original position across player-driven subtitle changes until manually moved or dismissed.
- **Dismissal**: Explicit confirmation of `Esc` as the primary mechanism for clearing the independent pointer state.

## Capabilities

### New Capabilities
- `independent-book-mode-pointer`: Defining the decoupled state of video focus and word focus in Book Mode to support non-linear consumption.

### Modified Capabilities
- `drum-window-navigation`: Updating manual seek requirements to enforce pointer independence when Book Mode is active.

## Impact

- `scripts/lls_core.lua`: Modification of `cmd_dw_seek_delta` and state management logic.
- `FSM` state: Refined handling of `DW_CURSOR_LINE` and `DW_CURSOR_WORD` updates.
