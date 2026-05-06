## 1. Drum Mode Rendering Pipeline Updates

- [x] 1.1 Update `tick_drum` in `lls_core.lua` to respect `FSM.DW_FOLLOW_PLAYER`. If `false`, use `FSM.DW_VIEW_CENTER` as the rendering reference.
- [x] 1.2 Ensure `FSM.DRUM_HIT_ZONES` are correctly populated when rendering the scrolled viewport to maintain interaction parity.

## 2. Mouse Wheel Interaction Hardening

- [x] 2.1 Refactor mouse wheel bindings in `manage_dw_bindings` to use a context-aware handler that checks for hit-test results when in Drum Mode.
- [x] 2.2 Verify and adjust wheel scroll direction (`WHEEL_UP` = -1, `WHEEL_DOWN` = +1) to ensure "natural" scrolling as requested.
- [x] 2.3 Implement hit-zone gating for the wheel in Drum Mode to prevent blocking default mpv wheel behavior when not hovering over subtitles.

## 3. State Synchronization and Cleanup

- [x] 3.1 Verify that `cmd_dw_seek_delta` (used by `a`/`d` keys) correctly resets `FSM.DW_FOLLOW_PLAYER` to `true`.
- [x] 3.2 Ensure double-click seeking in Drum Mode also resets the scroll state.
- [x] 3.3 Conduct regression testing to ensure standard Drum Window (Mode W) scrolling remains unaffected.
