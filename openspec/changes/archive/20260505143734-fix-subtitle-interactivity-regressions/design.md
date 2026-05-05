## Context

Subtitle interactivity in `lls_core.lua` relies on a shared state machine (`FSM`) between the Drum Window and standard OSD subtitles. Regressions have been identified where Drum Window behaviors (auto-scroll) leak into OSD mode, and immersion mode transitions fail to synchronize state properly.

## Goals / Non-Goals

**Goals:**
- Isolate Drum Window auto-scroll logic from standard OSD subtitles.
- Ensure seamless transitions between Movie and Phrase modes without unintended playback.
- Maintain accurate single-word selections in OSD mode.

**Non-Goals:**
- Modifying the underlying coordinate mapping system.
- Changing the visual appearance of the Drum Window.

## Decisions

- **Auto-scroll Guard**: Add a check for `FSM.DRUM_WINDOW == "OFF"` in `dw_mouse_auto_scroll`. This is the most surgical fix to prevent state mutation during OSD-only interactions.
- **Mode Synchronization**: Explicitly update `FSM.ACTIVE_IDX` using `get_center_index` during the `PHRASE` mode toggle. This aligns the state machine with the actual player position *before* the next tick loop executes, bypassing the "Jerk Back" seek.

## Risks / Trade-offs

- **Risk**: If `FSM.DRUM_WINDOW` state is somehow corrupted, auto-scroll might fail to trigger in the window.
- **Trade-off**: Synchronizing `ACTIVE_IDX` during toggle adds a small amount of logic to the hotkey handler but saves significant complexity in the main tick loop's boundary detection.
