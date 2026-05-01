## Context

The `cmd_dw_esc` function in `scripts/lls_core.lua` manages the `Esc` key behavior during Drum Window (`Mode W`) and Drum Mode (`Mode C`) interaction. Currently, it uses a 2-step logic that clears both the Pink set and the Yellow anchor in one step, but fails to account for cases where a single word is highlighted (where anchor and cursor are identical), leading to a redundant extra press.

## Goals / Non-Goals

**Goals:**
- Implement a 4-stage sequential Escape logic: Pink Set -> Yellow Range -> Yellow Pointer -> Exit.
- Ensure that clearing one level of selection does not prematurely clear the next level.
- Fix the regression where a single-word highlight requires two `Esc` presses.
- Use robust `logical_cmp` for selection boundary validation.

**Non-Goals:**
- Changing the colors or visual representation of selections.
- Modifying how selections are created (mouse/keyboard).
- Affecting the Search Mode (Ctrl+F) Escape logic.

## Decisions

- **Sequential Clearing**: Each `Esc` press will address exactly one level of state. If a higher-level state (e.g., Pink set) exists, it is cleared first. If not, we check for a multi-word Yellow range. If not, we check for a single-word Yellow pointer.
- **Robust Equality**: `get_dw_selection_bounds` will be updated to use `logical_cmp` instead of `==` for word indices to ensure consistency with the comma granularity system.
- **State Cleanup**: `cmd_dw_esc` will explicitly clear `DW_ANCHOR_LINE` when clearing the Yellow Pointer to ensure the state is fully reset for the next navigation action.

## Risks / Trade-offs

- **Interaction Latency**: Users who want to exit immediately while having many selection layers will need to press `Esc` multiple times. However, this matches the specified "Context-Aware" philosophy and prevents accidental window closing.
