## Context

Transitioning the Drum Window interaction model from a hardcoded, modifier-dependent system to a unified, list-based shortcut engine. This change addresses usability bottlenecks for minimalist remote controllers and enhances the pairing (Pink highlight) logic for complex phrase mining.

## Goals / Non-Goals

**Goals:**
- Provide a unified parser for multi-key shortcuts in `mpv.conf`.
- Enable range-based toggling from both keyboard (`t`) and mouse (`Ctrl+MBTN_LEFT`).
- Implement persistent selection state that survives modifier key release.
- Ensure instantaneous visual synchronization between the pointer and the focus cursor.

**Non-Goals:**
- Modifying the underlying color theme of the Drum Window.
- Changing the database schema for Anki exports.

## Decisions

- **Multi-Delimiter Configuration Parser**:
  - *Decision*: Use a robust `gmatch` pattern `"[^%s,;]+"` to parse shortcut lists.
  - *Rationale*: Allows users to use spaces, commas, or semicolons in `mpv.conf`, making the configuration more human-readable and resilient to different formatting styles.

- **Explicit Selection Persistence**:
  - *Decision*: Remove `ctrl_discard_set()` from the `Ctrl` key release tracker and move it to an explicit `Ctrl+ESC` binding.
  - *Rationale*: Releasing `Ctrl` shouldn't destroy the user's progress when building multi-word paired phrases. Explicit discard is safer for specialized mining workflows.

- **Synchronous Cursor Synchronization**:
  - *Decision*: Update `FSM.DW_CURSOR` and `FSM.DW_ANCHOR` immediately upon any mouse-triggered pairing action.
  - *Rationale*: Ensures the yellow visual focus "jumps" to the interaction point, providing immediate confirmation that the correct word is being targeted.

- **Range-Aware Toggling Architecture**:
  - *Decision*: Implement a `get_dw_selection_bounds` helper to detect active yellow selections and prioritize range-toggling over single-word toggling.
  - *Rationale*: Allows users to combine standard dragging (Yellow) with functional marking (Pink) in a single fluid motion.

## Risks / Trade-offs

- **Risk**: Users might forget to clear a pending pink selection since it no longer auto-discards.
  - **Mitigation**: Clear visual feedback of pink highlights and the addition of the explicit `Ctrl+ESC` shortcut.
- **Risk**: Complexity in `parse_and_bind` logic.
  - **Mitigation**: Use of closures to pass context (`is_mouse`) directly to callbacks, avoiding brittle event-string matching.
