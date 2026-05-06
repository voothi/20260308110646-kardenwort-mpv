# Proposal: Simplify Selection Logic via FSM State

## Problem
The current implementation of multi-tier selection priority in `get_clipboard_text_smart` involves complex nested loops and redundant sorting of the "Pink Set" (non-contiguous word selection). This logic is also duplicated in `ctrl_commit_set`, leading to high cyclomatic complexity and maintenance overhead.

## Solution
Shift the responsibility of maintaining the sorted selection state to the FSM. By introducing a `DW_CTRL_PENDING_LIST` that is synchronized whenever the selection changes, we can:
1. Reduce `get_clipboard_text_smart` to a simple conditional check.
2. Eliminate redundant code in `ctrl_commit_set`.
3. Improve performance by sorting only when the selection *changes*, rather than on every *copy* operation.

## Impact
- **Simpler Code**: `get_clipboard_text_smart` becomes much more readable.
- **Improved Maintainability**: Selection logic is centralized.
- **Architectural Alignment**: Follows the FSM-driven approach requested by the user.
