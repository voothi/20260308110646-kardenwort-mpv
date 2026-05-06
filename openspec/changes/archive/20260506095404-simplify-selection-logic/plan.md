# Implementation Plan - Simplify Selection Logic via FSM State

The user pointed out that the recently added multi-tier selection logic in `get_clipboard_text_smart` has high cyclomatic complexity due to nested loops and redundant sorting of the "Pink Set" (non-contiguous selection). To resolve this, we will move the collection and sorting logic into the FSM update cycle, maintaining a pre-sorted `DW_CTRL_PENDING_LIST` in the FSM state.

## Proposed Changes

### `scripts/lls_core.lua`

#### 1. Update `FSM` Initialization
- Add `DW_CTRL_PENDING_LIST = {}` to the `FSM` table.

#### 2. Create `sync_ctrl_pending_list()` Helper
- Implement a local function that gathers all members from `FSM.DW_CTRL_PENDING_SET`, sorts them by line/word index, and updates `FSM.DW_CTRL_PENDING_LIST`.

#### 3. Update `ctrl_toggle_word()`
- Call `sync_ctrl_pending_list()` whenever the set changes.

#### 4. Update Selection Reset Logic
- Ensure `FSM.DW_CTRL_PENDING_LIST` is cleared whenever `FSM.DW_CTRL_PENDING_SET` is reset (in `dw_reset_selection`, `cmd_dw_esc`, etc.).

#### 5. Refactor `ctrl_commit_set()`
- Replace the redundant sorting logic with a simple reference to `FSM.DW_CTRL_PENDING_LIST`.

#### 6. Refactor `get_clipboard_text_smart()`
- Simplify the selection priority check by using `FSM.DW_CTRL_PENDING_LIST` and extracting the hierarchy logic into a helper if necessary.

## Verification Plan

### Manual Verification
1. **Pink Set Copying**:
    - Select multiple words. Verify they are copied in document order.
2. **Esc Stages**:
    - Verify that clearing the Pink Set via `Esc` correctly falls back to Yellow Range -> Yellow Pointer -> Context Copy.
3. **Anki Export**:
    - Verify that adding words to Anki (MMB) still works correctly for both single words and Pink Sets.
