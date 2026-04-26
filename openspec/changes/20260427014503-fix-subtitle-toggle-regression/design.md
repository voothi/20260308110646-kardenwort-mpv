## Context

The `lls_core.lua` script implements a custom OSD-based subtitle rendering engine. This engine handles both "Drum Mode" (multi-line context) and a styled SRT mode. Currently, the logic in the main rendering loop (`master_tick`) gives Drum Mode priority over the global subtitle visibility toggle (`s` key), which is tracked in `FSM.native_sub_vis`. This results in a regression where subtitles cannot be hidden if Drum Mode is enabled.

## Goals / Non-Goals

**Goals:**
- Restore the `s/ы` key as the master visibility control for all subtitle rendering modes.
- Ensure OSD content is cleared immediately upon hiding subtitles.
- Maintain the "suppression" logic that hides native mpv subtitles when OSD is active to prevent double rendering.

**Non-Goals:**
- Changing the behavior of the Drum Window (Mode W), which is a separate interactive UI element and already manages its own visibility.
- Modifying how ASS tracks are handled (they will continue to be rendered natively when not in Drum Mode).

## Decisions

### Decision 1: Respect `FSM.native_sub_vis` in OSD calculation
We will modify the `pri_use_osd` and `sec_use_osd` flags in `master_tick` to be conditional on the respective visibility flags.

**Rationale:** This centralizes the visibility logic. If the user intends for subtitles to be hidden (`FSM.native_sub_vis == false`), the system should not "use OSD" for that track, regardless of whether Drum Mode is ON.

### Decision 2: Immediate OSD Clearing in `cmd_toggle_sub_vis`
The `cmd_toggle_sub_vis` function already calls `drum_osd:update()`. By updating the underlying flags used in the rendering loop, the next tick (or the manual update call) will correctly see that no tracks should be rendered and clear the `drum_osd.data`.

## Risks / Trade-offs

- **[Risk]** User confusion when toggling Drum Mode ON while subtitles are hidden.
- **[Mitigation]** Standard mpv behavior and script OSD feedback ("Subtitles: OFF") should make it clear that visibility is globally disabled. Toggling visibility ON with `s` will immediately show the Drum Mode OSD as expected.
