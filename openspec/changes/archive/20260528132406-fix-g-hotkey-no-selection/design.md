## Context

In Kardenwort, pressing the `g` hotkey (dw-add) exports the selection to Anki. When no yellow selection range or single-word pointer is active, it is designed to export the current subtitle line in its entirety. However, because it relied on `FSM.DW_CURSOR_LINE` which could be stale or lagging behind playback (especially in Book Mode where scrolling and cursor center synchronization differ), the `g` hotkey would often export the wrong subtitle (either late or ahead of time).

## Goals / Non-Goals

**Goals:**
- Resolve the `g` hotkey export target dynamically based on the exact live playback position (`time-pos`) at the millisecond of the keypress when there is no active selection.
- Keep the cursor selection state `FSM.DW_CURSOR_LINE` perfectly synchronized with `active_idx` during playback in all follow modes (including Book Mode) when no active selection exists, ensuring consistent state representation.

**Non-Goals:**
- Changing behavior when there is an active yellow range selection, yellow word pointer, or pink pending set.
- Modifying how Anki exports are saved or database formatting.

## Decisions

### Decision 1: Smart Fallback in dw_anki_export_selection()
- **Approach**: In `dw_anki_export_selection()`, if `FSM.DW_ANCHOR_LINE == -1` and `FSM.DW_CURSOR_WORD == -1` (denoting no active selection/pointer), resolve `cl` (cursor line) dynamically using the player's current `time-pos` (mapping to the center subtitle index via `get_center_index`), falling back to `FSM.DW_ACTIVE_LINE`.
- **Alternatives Considered**: Modifying the `master_tick` to be faster, which would introduce excessive CPU overhead and still not guarantee synchronization at the millisecond level of the keypress event.
- **Rationale**: Fetching the `time-pos` dynamically at the moment of the keypress guarantees 100% temporal accuracy, bypassing any tick loop latency or rendering lag.

### Decision 2: Harden Cursor Tracking in master_tick()
- **Approach**: In the universal cursor synchronization block of `master_tick()`, if `FSM.DW_FOLLOW_PLAYER` is true and no selection is active (`FSM.DW_ANCHOR_LINE == -1 and FSM.DW_CURSOR_WORD == -1`), continuously synchronize `FSM.DW_CURSOR_LINE` to `active_idx`. Do this for both Book Mode and standard centering mode.
- **Alternatives Considered**: Only synchronizing when the viewport centers, which causes `FSM.DW_CURSOR_LINE` to drift in Book Mode (since it scrolls page-by-page/line-by-line) and leads to mismatch between playback and the export cursor.
- **Rationale**: Continuously setting the copy cursor when following playback ensures the OSD and hotkey states are always visually and logically aligned, preventing any visual or logical drift.

## Risks / Trade-offs

- **[Risk]**: Drift between visual cursor and actual saved line during rapid playhead changes.
- **[Mitigation]**: The live playback `time-pos` is resolved directly at the keypress event, ensuring that the saved subtitle is exactly the one that is audible/visible at that moment.
