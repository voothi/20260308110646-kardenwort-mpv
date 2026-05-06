## Context

Currently, the "Drum Mode" (on-screen OSD subtitles) rendering is strictly tied to the current video playback position (`time_pos`). While the "Drum Window" (full-screen overlay) supports viewport scrolling via `FSM.DW_VIEW_CENTER` and `FSM.DW_FOLLOW_PLAYER`, these state variables are not utilized by the `tick_drum` rendering loop. This results in the mouse wheel being either bound to default mpv actions (seeking) or being a "dead" key when OSD interactivity is on.

## Goals / Non-Goals

**Goals:**
- Enable mouse wheel scrolling in Drum Mode to adjust the viewport without seeking.
- Synchronize Drum Mode scroll state with the global `FSM.DW_VIEW_CENTER` and `FSM.DW_FOLLOW_PLAYER`.
- Ensure scrolling only occurs when the mouse is hovering over the subtitle area in Drum Mode.
- Maintain consistency in scroll direction (WHEEL_DOWN = next subtitle).

**Non-Goals:**
- Implementing multi-track independent scrolling (primary/secondary scroll together).
- Changing the behavior of other interaction keys (like `a`, `d`, or clicks).

## Decisions

1. **State Reuse**: Reuse `FSM.DW_VIEW_CENTER` and `FSM.DW_FOLLOW_PLAYER` for Drum Mode. This ensures that if the user scrolls in Drum Mode and then opens the Drum Window, they are at the same position (and vice-versa).
2. **Conditional Rendering**: Modify `tick_drum` to check `FSM.DW_FOLLOW_PLAYER`. If `false`, use `FSM.DW_VIEW_CENTER` as the reference index instead of calculating it from `time_pos`.
3. **Scroll Direction Binding**: Explicitly map `WHEEL_UP` to `-1` and `WHEEL_DOWN` to `+1` in the interaction loop.
4. **Hit-Zone Requirement**: Restrict the scroll action to when the mouse is over a valid hit-zone (subtitle line) to prevent blocking the wheel for volume/seeking when the mouse is outside the subtitle area.

## Risks / Trade-offs

- **Interaction Complexity**: Overriding the wheel might confuse users who expect it to control volume or seeking. We mitigate this by restricting the override to the subtitle hit-zones.
- **Scroll Limit**: Viewport scrolling is limited by the subtitle track boundaries.
