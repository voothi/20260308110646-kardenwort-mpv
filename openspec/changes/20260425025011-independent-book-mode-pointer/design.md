## Context

In Book Mode, the Drum Window serves as a reading environment. Users often want to maintain focus on a specific word or sentence (the "anchor" or "pointer") while seeking the video to check pronunciation or context in other parts of the media. Currently, seeking with `a`/`d` keys resets the pointer, which disrupts this workflow.

## Goals / Non-Goals

**Goals:**
- Implement full decoupling of the yellow pointer from the active playback line during manual seeking in Book Mode.
- Ensure the yellow pointer remains visible and stationary in its original subtitle line across seek operations.
- Maintain the current behavior for regular (non-Book) mode where the cursor follows the player.

**Non-Goals:**
- Changing how the arrow keys navigate.
- Modifying the visual style of the highlights.

## Decisions

- **Decision: Conditional Logic in `cmd_dw_seek_delta`**
  - **Rationale**: By wrapping the cursor update in `if not FSM.BOOK_MODE then`, we achieve the desired independence with zero overhead and no new state variables. 
  - **Alternatives**: Introducing a separate `FSM.DW_BOOK_CURSOR` state, but this would complicate rendering and synchronization.

- **Decision: Rely on Manual Dismissal via Esc**
  - **Rationale**: Since the pointer no longer "auto-clears" during seeks in Book Mode, the user needs a clear way to remove it. `Esc` is already established as the "clear/back" key in this project.

## Risks / Trade-offs

- **[Risk] → Viewport Divergence**: The user might seek far away from the yellow pointer, leaving it off-screen. 
  - **Mitigation**: This is intended behavior for "Independent States". The user can use arrow keys or `Esc` to re-orient the cursor to the current viewport if needed.
