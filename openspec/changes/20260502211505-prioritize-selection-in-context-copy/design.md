## Context

Currently, the `cmd_dw_copy` and `cmd_copy_sub` functions check `FSM.COPY_CONTEXT == "ON"` as their first priority. If active, they harvest context lines around the current time or cursor position and return that text, bypassing the logic that handles specific word or range selections in the Drum Window.

## Goals / Non-Goals

**Goals:**
- Shift the priority of the copy operation so that any manual selection (pointer or range) is respected even if Context Copy is enabled.
- Maintain existing context copy behavior when no manual selection is active.
- Ensure consistency across different UI modes (Regular SRT, Drum Mode, Drum Window).

**Non-Goals:**
- Changing the actual text extraction logic of `get_copy_context_text`.
- Modifying how selections are created or cleared.

## Decisions

### 1. Unified Selection Check
Introduce a `has_selection` check at the beginning of `cmd_dw_copy` and `cmd_copy_sub`.
- For `cmd_dw_copy`, a selection is active if `FSM.DW_ANCHOR_LINE ~= -1` (range) or `FSM.DW_CURSOR_WORD ~= -1` (pointer).
- For `cmd_copy_sub`, the same logic applies, ensuring that if the Drum Window is open and a word is highlighted, pressing the global copy key will copy that word.

### 2. Logic Reordering
Move the `FSM.COPY_CONTEXT == "ON"` block to be an `elseif` after the selection check.

**New Priority Order:**
1. **Manual Range Selection**: `al ~= -1 and aw ~= -1`
2. **Manual Pointer Selection**: `cw ~= -1`
3. **Context Copy**: `FSM.COPY_CONTEXT == "ON"`
4. **Active Line Fallback**: Standard single-line copy.

## Risks / Trade-offs

- **Risk**: Users who are used to Context Copy always winning might be confused if they leave a "yellow cursor" on a word and then try to copy the full sentence.
- **Mitigation**: This is exactly what the user requested to allow "regulation" via `Esc`. Pressing `Esc` clears the pointer/selection, reverting to Context Copy behavior.
