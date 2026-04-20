## Context

The "Pointer Jump Sync" was implemented to ensure that a click applies to the exact release coordinate. However, for "Selection Protection" (where a user clicks inside an existing highlight to export it), this synchronization is destructive because it collapses the multi-word range to a single word.

## Goals / Non-Goals

**Goals:**
- Preserve multi-word selections when clicked with MMB.
- Maintain Pointer Jump Sync for standard clicks (non-protected).

**Non-Goals:**
- Change how selections are created (drag logic).

## Decisions

- **Decision: Use `FSM.DW_PROTECTED_SELECTION` flag**:
  - In `make_mouse_handler` -> `down` event: If click is inside selection, set `FSM.DW_PROTECTED_SELECTION = true`.
  - In `make_mouse_handler` -> `up` event: Only update `DW_CURSOR_LINE/WORD` if `FSM.DW_PROTECTED_SELECTION` is false.
  - Reset `FSM.DW_PROTECTED_SELECTION = false` at the end of the `up` event.
  - *Rationale*: Minimal change to the existing state machine while ensuring the release event doesn't corrupt the range.

## Risks / Trade-offs

- [Risk] → **Sticky Protection**: The flag might stay `true` if an error occurs.
- [Mitigation] → Ensure the flag is reset in the `up` event handler regardless of whether the callback succeeds.
