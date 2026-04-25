## Context

Relying on ASS automatic wrapping (`\q0`) made it impossible to know the exact pixel coordinates of wrapped words. Furthermore, rapid mouse movement was bottlenecked by the 50ms FSM polling loop, and native mpv window-dragging was causing "click theft."

## Goals / Non-Goals

**Goals:**
- Guarantee pixel-perfect alignment between rendered text and mouse hit-boxes.
- Achieve 60fps+ selection highlight responsiveness.
- Eliminate collisions between the Drum Window and native player/OS behaviors.

## Decisions

- **Hard-Coded Layouts**: `dw_build_layout` bypasses ASS smart-wrapping by calculating its own line breaks and using `\q2`. This creates a coordinate table that `dw_hit_test` uses for 1:1 matching.
- **Event-Driven Dragging**: Dragging is decoupled from the FSM timer. It now triggers on the `mouse_move` hardware event for instant feedback.
- **Environment Shielding**: 
    - `window-dragging` is disabled while the Drum Window is open.
    - All other subtitle layers are snapshotted and hidden to provide a clean reading environment.
- **Interaction Logic**:
    - `MBTN_LEFT_DBL` seeks to `start_time` and re-enables "Follow Player" mode.
    - `UP/DOWN` arrow keys check if the cursor is currently in the viewport; if not, they force a re-center (Snapback).

## Risks / Trade-offs

- **Risk**: Font-width estimation inaccuracy.
- **Mitigation**: Using a safety buffer and snapping logic in `dw_hit_test` to catch near-miss clicks.
