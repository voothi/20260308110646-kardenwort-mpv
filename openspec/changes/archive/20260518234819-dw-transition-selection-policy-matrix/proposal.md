## Why

The transition from Drum Window selection to playback seek (via `Enter` and double-click) had drifted into inconsistent behavior across `dw_clear_selection_after_transition` and `dw_esc_mode`. This caused practical confusion in study flow, especially in Book Mode and neutral Esc policies, where follow/manual behavior and pointer lifecycle must be deterministic.

## What Changes

- Formalize one transition policy matrix for `Enter` and double-click that defines how pointer, range/set selection, and follow state change after seek.
- Define exact interaction between `dw_clear_selection_after_transition` (`yes`/`no`) and `dw_esc_mode` (`auto_follow_current`, `neutral_last_selection`, `neutral_current_subtitle`).
- Standardize post-transition Esc arming behavior to avoid stale neutral arm state leaking across transitions.
- Specify parity requirements so double-click and Enter use the same post-transition state contract.
- Add acceptance requirements for Book Mode ON/OFF and all supported mode combinations.

## Capabilities

### New Capabilities
- `dw-transition-selection-policy`: Defines the canonical post-transition selection/follow matrix for Enter and double-click.

### Modified Capabilities
- `dw-esc-mode`: Clarify Esc neutral-arm lifecycle immediately after transition and recovery expectations.
- `dw-mouse-selection-engine`: Require parity between double-click transition state and Enter transition state.
- `drum-window-reading-mode`: Clarify when transition keeps manual mode versus restoring follow.

## Impact

- Affected code: `scripts/kardenwort/main.lua` transition handlers (`cmd_dw_seek_selected`, double-click path, shared post-transition state helper).
- Affected config: `kardenwort-dw_clear_selection_after_transition` semantics documented and validated.
- Affected tests: acceptance matrix coverage under `tests/acceptance/` for mode combinations, Book Mode interaction, and Esc recovery.
