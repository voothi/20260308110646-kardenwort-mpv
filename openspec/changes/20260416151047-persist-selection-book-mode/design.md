## Context

In `lls_core.lua`, the `cmd_dw_seek_delta(dir)` function is responsible for navigating between subtitles when the user presses `a` or `d`. Currently, this function unconditionally resets the selection state by setting `FSM.DW_ANCHOR_LINE`, `FSM.DW_ANCHOR_WORD`, and `FSM.DW_CURSOR_WORD` to `-1`. 

While this is standard behavior for linear video playback, "Book Mode" in the Drum Window is designed for deep textual study where the viewport remains static. In this mode, users expect the active yellow highlight to remain on the word they are analyzing even if they seek the audio to re-listen to previous or next segments.

## Goals / Non-Goals

**Goals:**
- Prevent selection reset during manual navigation (`a`/`d`) when `FSM.BOOK_MODE` is active.
- Ensure the Drum Window highlight remains visible and stable during audio seeks in Book Mode.

**Non-Goals:**
- Changing selection behavior in non-Book Mode.
- Modifying how primary/secondary subtitle tracks are handled during seek.
- Changing click-to-select behavior (which should still reset previous selection as natural).

## Decisions

### Unconditional Selection Persistence in `cmd_dw_seek_delta`
The logic in `cmd_dw_seek_delta` will be updated to remove the unconditional reset of selection state variables (`ANCHOR_LINE`, `ANCHOR_WORD`, `CURSOR_WORD`).

- **Rationale**: Manual navigation via `a`/`d` is often used to re-listen to segments while maintaining focus on a specific piece of text. By persisting the selection state, we allow the Drum Window to maintain the yellow highlight during seeks, matching the persistent behavior already observed during standard playback (spacebar).
- **Behavior**:
    - `DW_ANCHOR_LINE` and `DW_ANCHOR_WORD` are preserved.
    - `DW_CURSOR_WORD` is preserved.
    - `DW_CURSOR_LINE` is still updated to the target subtitle index (standard behavior for seeks).
- **Constraint**: This applies only to manual seeks (`a`/`d`). Mouse clicks on new lines will still naturally move both the cursor and the anchor, resetting the selection state as expected.

## Risks / Trade-offs

- **[Risk]** Selection indices might become invalid if the underlying subtitle data changes mid-seek.
    - **Mitigation**: Standard seek within a file doesn't change `Tracks.pri.subs` structure. Navigation `a`/`d` just changes `time-pos`.
- **[Risk]** Potential confusion if the user forgets they are in Book Mode.
    - **Mitigation**: Book Mode OSD notification is already present on toggle.
