## 1. Input Bindings & Configuration

- [x] 1.1 Add new parameters to the "Translation Tooltip Settings" section of `mpv.conf` (e.g., `lls-dw_tooltip_toggle_key=e` and `lls-dw_tooltip_toggle_key_ru=у`).
- [x] 1.2 Bind these configured keys to trigger the new tooltip toggle action within the script's initialization layout.

## 2. Core Implementation

- [x] 2.1 Implement a `toggle_tooltip()` or similar function in `lls_core.lua` (or the relevant Tooltip module) that manages a boolean state for keyboard-driven tooltip visibility.
- [x] 2.2 Restrict the `toggle_tooltip()` function execution to only occur when the Drum Window ('w') is currently open/active.
- [x] 2.3 Connect the toggle function to the existing tooltip rendering routine, ensuring it fetches the subtitle text based on the current playback time rather than relying on a mouse position intersection.
- [x] 2.4 Modify the tooltip dismiss logic to ensure it can be closed by the subsequent key press while not breaking hover-off behavior.

## 3. Dynamic Positioning (Scrolling)

- [x] 3.1 Modify the Drum Window rendering logic (`draw_dw`) to calculate and store the OSD Y-coordinates for every visible subtitle line.
- [x] 3.2 Implement a mechanism to retrieve a line's current on-screen Y-position by its subtitle index.
- [x] 3.3 Update the tooltip refresh logic (in `tick_dw` or similar) to reposition the active tooltip based on its line's current Y-position on every tick.
- [x] 3.4 Ensure the dynamic positioning applies to both keyboard-toggled (`FORCE`) and mouse-pinned (`HOLDING`) tooltips.

## 4. Context-Sensitive Targeting & Regressions

- [x] 4.1 Introduce `FSM.DW_TOOLTIP_TARGET_MODE` with values "ACTIVE" or "CURSOR".
- [x] 4.2 Initialize mode to "ACTIVE".
- [x] 4.3 Update `cmd_dw_seek_delta` (and related seek functions) to set mode to "ACTIVE" on interaction.
- [x] 4.4 Update `cmd_dw_line_move`, `cmd_dw_word_move` and `cmd_dw_mouse_select` to set mode to "CURSOR" on interaction.
- [x] 4.5 Update `dw_tooltip_mouse_update` to select `target_l` based on `FSM.DW_TOOLTIP_TARGET_MODE` while paused.
- [x] 4.6 Fix `cmd_dw_tooltip_toggle` to always dismiss when `FORCE` is active, regardless of current line match.
- [x] 4.7 Restore `CLICK` mode dismissal logic in `dw_tooltip_mouse_update` to handle RMB holding and coordinate-based pinning.
- [x] 4.8 Update `dw_tooltip_mouse_update` to make `HOLDING` (RMB) follow the current `line_idx` (mouse focus) rather than a pinned line.
- [x] 4.9 Add visibility check in `cmd_dw_tooltip_toggle` to prevent "blinking" for off-screen subtitles.
- [x] 4.10 Unified Selection Persistence: Remove anchor-clearing logic for single-word clicks to ensure yellow focus persists during `a`/`d` navigation in all modes.

## 5. Verification Checklist

### Keyboard Toggle ('e') & Book Mode
- [ ] 5.1 Test Playback: Tooltip follows white highlight automatically.
- [ ] 5.2 Test Seek while Paused ('a', 'd'): Tooltip switches to white highlight focus.
- [ ] 5.3 Test Cursor Move while Paused (arrows): Tooltip switches to yellow cursor focus.
- [ ] 5.4 Test LMB Click while Paused: Tooltip switches to yellow cursor focus.
- [ ] 5.5 Test Resume Playback: Tooltip returns to white highlight focus.
- [ ] 5.6 Verify "e" toggle for off-screen focus: No blinking artifacts, appears when scrolled in.

### Mouse Interactions (RMB)
- [ ] 5.7 Test RMB Drag: Hold RMB and swipe. Tooltip tracks mouse focus dynamically.
- [ ] 5.8 Test CLICK Mode Dismissal: Click a line, release, then move mouse away. Verify tooltip hides.
- [ ] 5.9 Test HOVER Mode Regression: Verify normal hover tooltips still work when nothing is forced/pinned.

### Global Regressions
- [ ] 5.10 Test Centered Mode (OFF): Verify tooltip follows centering logic as before.
- [ ] 5.11 Verify Toggle Dismissal: Pressing 'e' always hides a visible keyboard tooltip.
- [ ] 5.12 Verify RMB Override: Manual RMB interaction should clear keyboard-force state.
