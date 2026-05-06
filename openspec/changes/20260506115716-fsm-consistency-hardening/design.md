# Design: FSM Consistency Hardening

## Context
The current FSM implementation has drifted from the specification in three key areas:
1. `manage_search_bindings` fails to restore keyboard navigation for the Drum Window because it calls `manage_dw_bindings` with incomplete arguments.
2. `get_center_index` uses a "Sticky Focus Sentinel" that is too aggressive, preventing "Early Padding Handover" and thus disabling "Jerk-Back" transitions in Phrases mode.
3. `cmd_dw_word_move` and mouse handlers do not consistently synchronize the `DW_CURSOR_X` anchor, leading to horizontal coordinate drift during vertical navigation.

## Goals / Non-Goals

**Goals:**
- Restore full keyboard/mouse interactivity upon exiting search mode.
- Enable deterministic Jerk-Back transitions in Phrases mode by allowing early index switching in gaps.
- Synchronize the `DW_CURSOR_X` anchor with all manual focus changes (keyboard and mouse).

**Non-Goals:**
- Changing the visual style of the search HUD or Drum Window.
- Modifying the underlying tokenizer or hit-testing logic.

## Decisions

### 1. Unified Interactivity Restoration
Instead of manually calling `manage_dw_bindings(true)` in `manage_search_bindings(false)`, we will use the existing `update_interactive_bindings()` handler. This ensures that the state-driven logic for `need_mouse` and `need_kb` is respected, restoring full navigation capabilities.

### 2. Prioritized Overlap Detection
In `get_center_index`, the "Overlap Priority" check (which detects if we've entered the next sub's padding) will be moved to the very top of the function, before the "Sticky Focus Sentinel." 
**Rationale:** In Phrases mode, the overlap is the critical decision point for Jerk-Back. By switching the index early, we allow `master_tick` to detect `active_idx > FSM.ACTIVE_IDX` and perform the jump.

### 3. Immediate Anchor Synchronization
- In `cmd_dw_word_move`, we will explicitly update `FSM.DW_CURSOR_X` using `dw_compute_word_center_x` after every successful horizontal move.
- In `make_mouse_handler`, we will ensure that `FSM.DW_CURSOR_X` is recalculated or invalidated on click to ensure the "Sticky Column" logic starts from the correct horizontal offset.

## Risks / Trade-offs
- **Jerk-Back Frequency**: Early handover might increase the frequency of Jerk-Back triggers in very tight subtitle sequences. We will rely on `Options.nav_tolerance` to prevent jitter.
- **Performance**: Recalculating `DW_CURSOR_X` on every move is a minor O(1) cost that is negligible compared to the rendering overhead.
