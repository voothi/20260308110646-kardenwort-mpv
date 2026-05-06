# Implementation Plan - Prioritize Selection in Context Copy

The user wants to ensure that manual selections (Pink Set, Yellow Range, or Yellow Pointer/Cursor) take priority over the "Context Copy" mode. This allows for precise copying of specific terms or ranges even when multi-line context harvesting is active. The user can "regulate" this by pressing `Esc` to clear selections in stages, eventually reverting to the Context Copy behavior when no selection remains.

## Proposed Changes

### `scripts/lls_core.lua`

#### 1. Update `get_clipboard_text_smart`
- Add a check for the "Pink Set" (`FSM.DW_CTRL_PENDING_SET`) as the highest priority.
- Ensure "Yellow Range" and "Yellow Pointer" (`cw ~= -1`) also take priority over Context Copy.
- Only if no manual selection is active, proceed to check `FSM.COPY_CONTEXT == "ON"`.

## Verification Plan

### Manual Verification
1. **Context Copy ON**:
    - Select a few words using Ctrl+Click (Pink Set). Press Copy. Verify ONLY those words are copied.
    - Press `Esc` (Stage 1). Pink Set should be gone.
    - Select a range (Yellow Range). Press Copy. Verify ONLY the range is copied.
    - Press `Esc` (Stage 2). Yellow Range should be gone.
    - Select a word (Yellow Pointer). Press Copy. Verify ONLY that word is copied.
    - Press `Esc` (Stage 3). Yellow Pointer should be gone.
    - Press Copy. Verify the full context (e.g., +/- 2 lines) is copied.
2. **Context Copy OFF**:
    - Verify that selections still take priority (as they do now).
    - Verify that with no selection, only the active line is copied.
