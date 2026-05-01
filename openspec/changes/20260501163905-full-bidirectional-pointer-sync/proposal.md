# Proposal: Full Bidirectional Pointer Synchronization

## Problem Statement
Currently, the yellow word pointer (indicator) in Kardenwort is only partially synchronized across modes. While closing the Drum Window (Mode W) preserves the pointer position in Drum Mode (Mode C), the reverse is not true: opening the Drum Window explicitly resets the pointer, forcing the user to re-navigate. Furthermore, "Regular SRT" mode (windowless/drumless) lacks consistent interaction with the global pointer state, leading to disjointed UX when transitioning between immersion layouts.

## Objectives
- Achieve 100% bidirectional pointer synchronization between all viewing modes (Mode C, Mode W, and Regular SRT).
- Ensure that opening the Drum Window (Mode W) preserves the active word pointer and centers the viewport on that line.
- Standardize pointer behavior so that a highlight created in any mode remains logically anchored and visually persistent across all layout transitions until explicitly cleared.

## Proposed Changes
- Refactor `cmd_toggle_drum_window` to remove the explicit `DW_CURSOR_WORD = -1` reset during the opening phase.
- Implement logic in `cmd_toggle_drum_window` to synchronize `DW_VIEW_CENTER` with `DW_CURSOR_LINE` if a pointer is already active.
- Ensure all OSD rendering paths (Drum, Window, SRT) consistently respect the shared `FSM` pointer state.

## Modified Capabilities
- `drum-window`: Update toggle logic to preserve cursor state and viewport alignment.
- `subtitle-rendering`: Ensure uniform pointer visibility across all layout modes.
