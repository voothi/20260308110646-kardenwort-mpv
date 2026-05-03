## Context

The Translation Tooltip is rendered via `dw_tooltip_osd` and its hit-zones are stored in `FSM.DW_TOOLTIP_HIT_ZONES`. Currently, the `dw_tooltip_mouse_update` function handles the lifecycle of the visual OSD but neglects the logical hit-zone metadata. This leads to persistent "ghost" zones that block interaction with the Drum Window (`W`).

## Goals / Non-Goals

**Goals:**
- Implement strict synchronization between tooltip visibility and hit-zone availability.
- Harden the hit-test engine to ignore stale metadata.
- Prevent interaction collisions between the Tooltip and the Drum Window.

**Non-Goals:**
- Refactoring the entire hit-test system.
- Changing the layout or styling of the tooltip.

## Decisions

- **Explicit Metadata Clearing**: `FSM.DW_TOOLTIP_HIT_ZONES` will be set to `nil` in all branches of `dw_tooltip_mouse_update` where the tooltip is dismissed (dragging, timeout, or manual toggle).
- **Early Exit in Hit-Test**: Add a check to `dw_tooltip_hit_test` to verify `FSM.DW_TOOLTIP_LINE ~= -1`. This ensures that even if a race condition leaves metadata behind, it cannot steal focus if the tooltip is logically inactive.
- **Maintain Priority**: Tooltip will still have priority over the Drum Window when *active*, but the "active" state will be strictly enforced.

## Risks / Trade-offs

- **Risk: Jitter** -> If the hit-zones are cleared too aggressively in "gaps" between words, the tooltip might flicker. 
  - **Mitigation**: The `FSM.DW_TOOLTIP_HOLDING` (RMB hold) state already protects against jitter; clearing will respect this existing logic.
