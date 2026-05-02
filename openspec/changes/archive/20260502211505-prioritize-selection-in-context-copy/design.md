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

### 1. Unified Extraction Engine (`get_clipboard_text_smart`)
Instead of duplicating selection logic in multiple handlers, a local helper function `get_clipboard_text_smart` is introduced. This function encapsulates the entire priority state machine, including:
- **Smart Fallback**: Resolves the target line index based on cursor state, Book Mode follow logic, or video timestamp.
- **Selection Detection**: Uses `get_dw_selection_bounds` to identify range selections vs. single-word pointer selections.
- **Priority Routing**: Enforces the new hierarchy where manual selections override context harvesting.

### 2. Logic Reordering
The copy state machine now follows a strict priority order within the unified helper:

1. **Manual Range Selection**: If an anchor and cursor form a valid range.
2. **Manual Pointer Selection**: If the "yellow cursor" (`cw`) is active.
3. **Context Copy**: If `FSM.COPY_CONTEXT` is "ON" and no selection exists.
4. **Active Line Fallback**: Standard single-line copy for the current focal point.

### 3. Command Simplification
Both `cmd_dw_copy` and `cmd_copy_sub` are refactored into thin wrappers around the `get_clipboard_text_smart` engine. This ensures 100% behavioral parity regardless of whether the copy is triggered via a Drum Window hotkey or a global shortcut.

## Risks / Trade-offs

- **Risk**: Users who are used to Context Copy always winning might be confused if they leave a "yellow cursor" on a word and then try to copy the full sentence.
- **Mitigation**: This is exactly what the user requested to allow "regulation" via `Esc`. Pressing `Esc` clears the pointer/selection, reverting to Context Copy behavior.
