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

## 4. Verification

- [x] 4.1 Test that the tooltip follows its associated line when scrolling the Drum Window.
- [x] 4.2 Verify that the tooltip remains correctly positioned even when the Drum Window layout changes (e.g., resizing or different "book mode" alignments).
- [x] 4.3 Test that keyboard 'e' toggle and RMB pin still work correctly with dynamic tracking.
- [x] 4.4 Regress mouse hover behavior.
