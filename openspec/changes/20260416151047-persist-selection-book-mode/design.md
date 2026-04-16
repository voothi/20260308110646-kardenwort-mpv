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

- **Rationale**: Manual navigation via `a`/`d` is often used to re-listen to segments while maintaining focus on a specific piece of text. By persisting the selection state, we allow the Drum Window to maintain the yellow highlight during seeks.
- **Playback-Aware Tooltip Targeting**:
    - To prevent the tooltip from jumping between active playback and selection cursor, the `DW_TOOLTIP_TARGET_MODE` will be reset to `"ACTIVE"` whenever playback starts (`pause` property becomes `false`).
    - This ensures that while listening, the tooltip follows the current audio. After an autopause, it remains at the last played subtitle instead of snapping back to a stale selection.
    - Interaction with the selection cursor (arrows, clicks, or manual shifts) will restore `"CURSOR"` mode.
- **Selection Stability (Fixing Stretching)**: 
    - To prevent selections from "stretching" as the playback cursor moves, the update logic for `DW_CURSOR_LINE` (both in `tick_dw` and `cmd_dw_seek_delta`) will be made conditional.
    - If `DW_ANCHOR_LINE` is valid (`~= -1`), `DW_CURSOR_LINE` SHALL NOT be automatically synchronized with the active playback index in Standard Mode. This keeps the selection range locked to its original subtitle lines.
- **Eliminating Phantom Highlights**:
    - If `DW_ANCHOR_LINE` is NOT valid when seeking or navigating, `DW_CURSOR_WORD` SHALL be reset to `-1`. This ensures that a single yellow word doesn't "track" the playback cursor when the user hasn't explicitly made a selection.

## Risks / Trade-offs

- **[Risk]** Selection indices might become invalid if the underlying subtitle data changes mid-seek.
    - **Mitigation**: Standard seek within a file doesn't change `Tracks.pri.subs` structure. Navigation `a`/`d` just changes `time-pos`.
- **[Risk]** Potential confusion if the user forgets they are in Book Mode.
    - **Mitigation**: Book Mode OSD notification is already present on toggle.
