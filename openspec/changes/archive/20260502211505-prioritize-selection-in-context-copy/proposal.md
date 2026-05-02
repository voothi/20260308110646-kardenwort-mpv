# Proposal: Prioritize Selection in Context Copy

## Problem

Currently, when "Context Copy" mode is active (`FSM.COPY_CONTEXT == "ON"`), the script prioritizes copying the surrounding dialogue context (e.g., +/- 2 lines) regardless of whether the user has a specific word or range selected in the Drum Window. This makes it impossible to copy a single word or a specific phrase without first disabling Context Copy, which is counter-intuitive and slows down the workflow.

The user wants the ability to "regulate" this behavior using the `Esc` key. Since `Esc` clears selections and cursors in stages, prioritizing selection over context allows the user to:
1. Select a word -> Copy copies the word.
2. Press Esc (clears word) -> Copy copies the context (if ON).
3. Press Esc (clears anchor) -> Copy copies the context (if ON).

## What Changes

- Modify the copy logic in both `cmd_dw_copy` and `cmd_copy_sub` to check for active selections (Pointer or Range) before checking the Context Copy state.
- Ensure that if a selection exists, it is copied verbatim, bypassing the multi-line context harvest.
- If no selection exists, the behavior remains unchanged (Context Copy takes precedence over the active line).

## Capabilities

### Modified Capabilities
- `context-copy`: Prioritize manual selections (pointer/range) over context harvest.
- `dw-mouse-selection-engine`: Ensure copy commands accurately reflect the interactive state of the Drum Window.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `cmd_dw_copy` and `cmd_copy_sub`).
- **UX**: Improved precision for users who frequently switch between copying individual words and full context.
