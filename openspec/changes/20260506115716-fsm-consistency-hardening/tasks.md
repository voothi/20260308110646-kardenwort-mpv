# Tasks: FSM Consistency Hardening

## 1. Interactivity Restoration

- [x] 1.1 Update `manage_search_bindings(false)` in `lls_core.lua` to call `update_interactive_bindings()` instead of the incomplete `manage_dw_bindings(true)`.
- [x] 1.2 Verify that closing Search HUD with ESC or Enter restores both mouse and keyboard navigation in the Drum Window.

## 2. Early Padding Handover (Phrases Mode)

- [x] 2.1 Refactor `get_center_index` in `lls_core.lua`: Move the "Overlap Priority" check (detecting next sub's padded start) to the top of the function, before the "Sticky Focus Sentinel."
- [x] 2.2 Verify that in Phrases mode, the playhead "Jerks Back" correctly when crossing into the next subtitle's padded start, even if still within the current subtitle's padded end.

## 3. Sticky-X Anchor Synchronization

- [x] 3.1 Update `cmd_dw_word_move`: Ensure `FSM.DW_CURSOR_X` is recalculated using `dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE])` after every horizontal word step.
- [x] 3.2 Update `make_mouse_handler`: Ensure `FSM.DW_CURSOR_X` is invalidated or updated upon mouse click to ensure vertical navigation follows the new focus point.
- [x] 3.3 Verify that manual horizontal navigation (Shift+Left/Right or Click) correctly updates the vertical "Sticky Column" anchor.

## 4. Documentation & Verification

- [x] 4.1 Update `openspec/specs/fsm-architecture/state-diagram.md` to reflect the prioritized "Overlap Priority" in the `get_center_index` logic diagram.
- [x] 4.2 Perform a final regression test of the search-exit/nav-recovery cycle.
