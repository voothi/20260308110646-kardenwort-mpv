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

### Conditional Selection Reset in `cmd_dw_seek_delta`
The logic in `cmd_dw_seek_delta` will be updated to wrap the selection reset in a check for `FSM.BOOK_MODE`.

- **Rationale**: In Book Mode, the viewport is decoupled from playback. Selection is tied to the monospace text grid of the Drum Window. Since the grid doesn't move in Book Mode, the selection indices remain valid and should be preserved.
- **Alternatives**: 
    - Storing selection separately: Overly complex, `FSM` properties are already the source of truth.
    - Re-applying selection after seek: Would cause a flicker and requires tracking "last book mode selection".

## Risks / Trade-offs

- **[Risk]** Selection indices might become invalid if the underlying subtitle data changes mid-seek.
    - **Mitigation**: Standard seek within a file doesn't change `Tracks.pri.subs` structure. Navigation `a`/`d` just changes `time-pos`.
- **[Risk]** Potential confusion if the user forgets they are in Book Mode.
    - **Mitigation**: Book Mode OSD notification is already present on toggle.
