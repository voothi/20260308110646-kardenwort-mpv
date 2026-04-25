## Context

The previous Drum Window was too tightly coupled to the video's current `time_pos`, making it difficult to read ahead or select specific text while the video was playing or paused. This release introduces a "frozen" state for the viewport to solve these friction points.

## Goals / Non-Goals

**Goals:**
- Decouple the viewport from playback when the user is actively navigating.
- Support text-editor style selection (word-by-word and line-by-line).
- Ensure the viewport "re-attaches" to playback after a seek event.

## Decisions

- **Operational States**:
    - **Follow Mode**: The viewport scrolls automatically to keep the current subtitle centered.
    - **Manual Mode**: Triggered by `UP`, `DOWN`, `LEFT`, or `RIGHT`. The viewport remains static unless the cursor hits an edge (edge-scrolling).
- **Selection FSM**: A new sub-state in the FSM tracks the `selection_anchor`. If `Shift` is held, the system calculates the range between the anchor and the current cursor.
- **Seek Intercept**: The `a` and `d` handlers are updated to reset the `Manual Mode` flag and clear all selection highlights.
- **Formatting Constraints**: `\q0` is applied to all context lines in the OSD rendering to enforce wrapping and prevent horizontal truncation.

## Risks / Trade-offs

- **Risk**: Confusion if the user forgets they are in Manual Mode.
- **Mitigation**: The automatic reset on seek provides a reliable "escape" back to synchronized playback.
