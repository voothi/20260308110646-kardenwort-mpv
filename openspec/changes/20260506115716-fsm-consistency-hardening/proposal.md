# Proposal: FSM Consistency Hardening

## ZID: 20260506115716

## Goal
Resolve architectural inconsistencies and functional regressions identified during the FSM audit, specifically targeting search-exit binding restoration, phrase-mode padding overlaps (The Padding Trap), and sticky-X coordinate synchronization during manual interaction.

## Context
A recent deep-dive audit into the `fsm-architecture` specification revealed three points of divergence between the "Source of Truth" (state-diagram.md) and the actual implementation in `lls_core.lua`. These regressions compromise the "Premium" feel of the immersion engine by causing navigation lockups and jittery phrase transitions.

## What Changes
- **Search-Exit Binding Logic**: Refactor `manage_search_bindings(false)` to correctly restore both mouse and keyboard interactivity for the Drum Window by using the unified `update_interactive_bindings()` handler.
- **Phrases Mode Transition Logic**: Decouple the "Sticky Focus Sentinel" from the "Overlap Priority" check in `get_center_index` to ensure that Jerk-Back logic fires correctly at the start of a padded gap, rather than being delayed until the gap ends.
- **Sticky-X Synchronization**: Enforce `DW_CURSOR_X` invalidation or immediate re-calculation during horizontal navigation (`cmd_dw_word_move`) to prevent horizontal "snapping" during subsequent vertical navigation.

## Capabilities

### Modified Capabilities
- `fsm-architecture`: Hardening requirements for state-transition consistency and interaction-shielding synchronization.

## Impact
- `scripts/lls_core.lua`: Significant logic refinement in `master_tick`, `get_center_index`, `manage_search_bindings`, and `cmd_dw_word_move`.
- `openspec/specs/fsm-architecture/state-diagram.md`: Minor documentation updates to reflect the resolved "Padding Trap" logic.
