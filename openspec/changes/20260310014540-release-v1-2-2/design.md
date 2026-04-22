## Context

The transition to v1.2.0 FSM architecture inadvertently introduced a "strict-radius" logic for Context Copy that failed on interleaved `.ass` files. Files alternating between English and Russian tracks caused the script to harvest the wrong ratio of languages, which were then deleted by the ASS filter, leaving fragmented output.

## Goals / Non-Goals

**Goals:**
- Ensure symmetrical context extraction (e.g., exactly 2 sentences before and 2 after).
- Prevent "center-index collapse" where the pivot points to a filtered track.
- Restore the `is_context` parsing optimization.

## Decisions

- **Dynamic Look-back/Forward**: Replaced strict radii `[idx-2 to idx+2]` with `while` loops that continue searching until the requested number of *valid* (unfiltered) strings is found.
- **Pivot Snapping**: The `get_center_index` resolution block is updated to check `idx+1` and `idx-1` if the current pivot lands on a filtered foreign-language block. It snaps to the native-language block sharing the identical timestamp.
- **Clipboard Pipeline**: The `is_context` string-bypassing optimization is restored to the clipboard pipeline to reduce redundant overhead.

## Risks / Trade-offs

- **Risk**: Indefinite loops if no valid strings are found.
- **Mitigation**: The `while` loops are bounded by the subtitle array limits and have strict exit conditions based on the quota.
