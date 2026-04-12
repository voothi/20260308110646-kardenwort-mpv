## Context

The Drum Window tooltips currently operate using a "Focus-Reset" logic where a tooltip is shown whenever the mouse focus matches a line index. There is no mechanism to temporarily suppress this focus matching while the user is engaged in other mouse-driven tasks like text selection.

## Goals / Non-Goals

**Goals:**
- Implement a "Suppression Lock" for tooltips triggered by LMB actions.
- Ensure tooltips stay hidden during multi-line drags.
- Prevent tooltips from reappearing immediately after a selection release until the user moves to a new line.

**Non-Goals:**
- Modifying tooltip rendering or positioning.
- Adding new configuration options for suppression sensitivity.

## Decisions

### Suppression Logic via FSM State
We will introduce `DW_TOOLTIP_LOCKED_LINE` to the `FSM` table. This variable will track the line where suppression was initiated.

**Rationale**: Using a line index instead of a boolean allows for the "sticky" release behavior: we know exactly which line to keep suppressed even after the LMB is released.

### Mouse Handler Integration
Update `make_mouse_handler` to set the suppression state on both `down` and `up` events.

**Process**:
1. On `down`: Clear active tooltip OSD and set `FSM.DW_TOOLTIP_LOCKED_LINE` to the current line index.
2. On `up`: Re-set `FSM.DW_TOOLTIP_LOCKED_LINE` to the current focus line (ensures drag-end suppression).

### Interaction Recovery via RMB
`cmd_dw_tooltip_pin` (RMB) must explicitly clear the `FSM.DW_TOOLTIP_LOCKED_LINE` to `-1` on its `down` event. This ensures manual hints takes precedence over the suppression lock.

### Tooltip Tick Guard
Modify `dw_tooltip_mouse_update` to respect the suppression lock.

**Logic**:
- IF `FSM.DW_MOUSE_DRAGGING` is true OR `line_idx == FSM.DW_TOOLTIP_LOCKED_LINE`:
    - Force tooltip OSD data to empty and reset `FSM.DW_TOOLTIP_LINE`.
- IF `line_idx ~= FSM.DW_TOOLTIP_LOCKED_LINE` AND `FSM.DW_MOUSE_DRAGGING` is false:
    - Clear `FSM.DW_TOOLTIP_LOCKED_LINE = -1`.
    - Resume normal hover/pin logic.

## Risks / Trade-offs

- **[Risk]**: If hit-testing fails at the edge of the window, the lock might not clear correctly. 
- **[Mitigation]**: Ensure `line_idx == -1` (no focus) also clears the lock if not dragging.
